import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

abstract interface class AuthRemoteDataSource {
  /// Emails a sign-in code to the account with this [email].
  Future<void> sendOtp({required String email});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  });

  /// Checks whether [email] is already registered.
  Future<bool> isEmailRegistered(String email);

  /// Saves the business signup data.
  Future<void> saveBusinessSignUp(BusinessSignUp data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> sendOtp({required String email}) async {
    // Login never creates an account; the sign-up screens do (GRA-10).
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: false);
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
    final user = response.user;
    if (user == null) {
      throw const AuthException('The code was accepted without a user');
    }
    return AuthSessionModel.fromJson(user.toJson());
  }

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
