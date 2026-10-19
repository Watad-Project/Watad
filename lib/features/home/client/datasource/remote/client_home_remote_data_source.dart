import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';
import 'package:watad/features/home/client/datasource/models/client_suggested_contractor_model.dart';

abstract interface class ClientHomeRemoteDataSource {
  Future<ClientHomeProfileModel> getProfile();

  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors();
}

class ClientHomeRemoteDataSourceImpl implements ClientHomeRemoteDataSource {
  const ClientHomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// How many contractors the home screen suggests.
  static const int _suggestedCount = 10;

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
  Future<List<ClientSuggestedContractorModel>> getSuggestedContractors() async {
    final rows = await _client
        .from('v_public_profiles')
        .select('id, company_name, avatar_path, rating_avg, rating_count')
        .eq('is_business', true)
        .eq('is_verified_business', true)
        .eq('is_deleted', false)
        .order('rating_avg', ascending: false, nullsFirst: false)
        .order('rating_count', ascending: false)
        .limit(_suggestedCount);
    return [
      for (final row in rows)
        ClientSuggestedContractorModel.fromJson({
          ...row,
          'avatar_url': _avatarUrl(row['avatar_path'] as String?),
        }),
    ];
  }

  /// Avatars live in the public `avatars` bucket.
  String? _avatarUrl(String? path) => path == null || path.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(path);
}
