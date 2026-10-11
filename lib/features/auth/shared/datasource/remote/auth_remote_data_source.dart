import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

abstract interface class AuthRemoteDataSource {
  Future<bool> isEmailRegistered(String email);

  Future<void> saveBusinessSignUp(BusinessSignUp data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isEmailRegistered(String email) async {
    final rows = await _client
        .from('v_public_profiles')
        .select('id')
        .eq('email', email.trim().toLowerCase())
        .limit(1);
    return rows.isNotEmpty;
  }

  @override
  Future<void> saveBusinessSignUp(BusinessSignUp data) async {
    // In sign-up flow, temporary client-side / auth session data is recorded
    // before the auth verification / license upload step.
    return;
  }
}
