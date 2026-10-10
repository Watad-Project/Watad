import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';

/// Remote data source contract for authentication with Supabase.
abstract interface class AuthRemoteDataSource {
  /// Calls Supabase to send an OTP to the given [email].
  Future<void> sendOtp({required String email});

  /// Calls Supabase to verify the [token] for [email] and returns the session model.
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  });
}

/// Supabase implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> sendOtp({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    return AuthSessionModel.fromAuthResponse(response);
  }
}
