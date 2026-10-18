import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ContractorOnboardingRemoteDataSource {
  Future<void> saveSpecialty(String specialty);
}

class ContractorOnboardingRemoteDataSourceImpl
    implements ContractorOnboardingRemoteDataSource {
  const ContractorOnboardingRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> saveSpecialty(String specialty) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User not authenticated');
    }
    await _client
        .from('businesses')
        .update({'specialized_field': specialty})
        .eq('user_id', userId);
  }
}
