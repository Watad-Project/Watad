import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/home/client/datasource/models/client_contractor_model.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';
import 'package:watad/features/home/client/domain/entities/client_contractors_query.dart';

abstract interface class ClientHomeRemoteDataSource {
  Future<ClientHomeProfileModel> getProfile();

  Future<List<ClientContractorModel>> getSuggestedContractors();

  Future<List<ClientContractorModel>> getContractors(
    ClientContractorsQuery query,
  );
}

class ClientHomeRemoteDataSourceImpl implements ClientHomeRemoteDataSource {
  const ClientHomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// How many contractors the home screen suggests.
  static const int _suggestedCount = 5;

  static const String _contractorColumns =
      'id, company_name, avatar_path, rating_avg, rating_count';

  @override
  Future<ClientHomeProfileModel> getProfile() async {
    final row = await _client
        .from('v_my_profile')
        .select('full_name')
        .maybeSingle();
    return ClientHomeProfileModel.fromJson({
      ...?row,
      // Confirmed with a code. A number saved at sign-up isn't verified.
      'is_phone_verified': _client.auth.currentUser?.phoneConfirmedAt != null,
    });
  }

  @override
  Future<List<ClientContractorModel>> getSuggestedContractors() async {
    final rows = await _verifiedContractors()
        // Highest rated first; contractors without ratings last.
        .order('rating_avg', ascending: false, nullsFirst: false)
        .order('rating_count', ascending: false)
        .limit(_suggestedCount);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<ClientContractorModel>> getContractors(
    ClientContractorsQuery query,
  ) async {
    final filter = query.filter;
    var request = _verifiedContractors();
    final name = filter.query.trim();
    if (name.isNotEmpty) {
      request = request.ilike('company_name', '%${_escapeLike(name)}%');
    }
    if (filter.minRating case final minRating?) {
      request = request.gte('rating_avg', minRating);
    }
    final rows = await request
        .order('rating_avg', ascending: false, nullsFirst: false)
        .order('rating_count', ascending: false)
        .order('company_name', ascending: true)
        .range(query.offset, query.offset + query.limit - 1);
    return rows.map(_toModel).toList();
  }

  /// Verified businesses that still have an account.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _verifiedContractors() {
    return _client
        .from('v_public_profiles')
        .select(_contractorColumns)
        .eq('is_business', true)
        .eq('is_verified_business', true)
        .eq('is_deleted', false);
  }

  ClientContractorModel _toModel(Map<String, dynamic> row) {
    final path = row['avatar_path'] as String?;
    return ClientContractorModel.fromJson({
      ...row,
      // Avatars live in the public `avatars` bucket.
      'avatar_url': path == null || path.isEmpty
          ? null
          : _client.storage.from('avatars').getPublicUrl(path),
    });
  }

  /// Searches for [text] as typed: `%` and `_` aren't wildcards.
  static String _escapeLike(String text) =>
      text.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
}
