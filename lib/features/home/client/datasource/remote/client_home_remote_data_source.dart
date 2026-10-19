import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/home/client/datasource/models/client_contractor_model.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_sort.dart';
import 'package:watad/features/home/client/domain/entities/client_contractors_query.dart';

abstract interface class ClientHomeRemoteDataSource {
  Future<ClientHomeProfileModel> getProfile();

  Future<List<ClientContractorModel>> getSuggestedContractors();

  Future<List<ClientContractorModel>> getContractors(
    ClientContractorsQuery query,
  );

  Future<List<String>> getContractorCities();
}

class ClientHomeRemoteDataSourceImpl implements ClientHomeRemoteDataSource {
  const ClientHomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// How many contractors the home screen suggests.
  static const int _suggestedCount = 5;

  static const String _contractorColumns =
      'id, company_name, avatar_path, city, rating_avg, rating_count, '
      'completed_project_count, is_in_my_city';

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
    final rows = await _client
        .from('v_contractors')
        .select(_contractorColumns)
        // The client's city first, then the best rated.
        .order('is_in_my_city', ascending: false)
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
    var request = _client.from('v_contractors').select(_contractorColumns);
    final name = filter.query.trim();
    if (name.isNotEmpty) {
      request = request.ilike('company_name', '%${_escapeLike(name)}%');
    }
    if (filter.city case final city?) {
      request = request.eq('city', city);
    }
    if (filter.minRating case final minRating?) {
      request = request.gte('rating_avg', minRating);
    }
    if (filter.minProjects case final minProjects?) {
      request = request.gte('completed_project_count', minProjects);
    }
    // The client's city first, then the chosen order.
    var ordered = request.order('is_in_my_city', ascending: false);
    ordered = switch (filter.sort) {
      ClientContractorSort.rating =>
        ordered
            .order('rating_avg', ascending: false, nullsFirst: false)
            .order('rating_count', ascending: false),
      ClientContractorSort.projects =>
        ordered
            .order('completed_project_count', ascending: false)
            .order('rating_avg', ascending: false, nullsFirst: false),
    };
    final rows = await ordered
        .order('company_name', ascending: true)
        .range(query.offset, query.offset + query.limit - 1);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<String>> getContractorCities() async {
    final rows = await _client
        .from('v_contractors')
        .select('city')
        .not('city', 'is', null);
    final cities = {
      for (final row in rows)
        if ((row['city'] as String?)?.trim() case final city?
            when city.isNotEmpty)
          city,
    }.toList()..sort();
    return cities;
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
