import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';

abstract interface class AuthRemoteDataSource {
  /// Emails a sign-in code to the account with this [email].
  Future<void> sendOtp({required String email});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  });

  Future<void> sendSignUpOtp(String email);

  Future<AuthSessionModel> verifySignUpOtp(VerifyOtpParams params);

  Future<void> saveProfile(SignUpProfile profile);
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
  Future<void> sendSignUpOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim().toLowerCase(),
      shouldCreateUser: true,
    );
  }

  @override
  Future<AuthSessionModel> verifySignUpOtp(VerifyOtpParams params) async {
    final response = await _client.auth.verifyOTP(
      email: params.email.trim().toLowerCase(),
      token: params.token.trim(),
      type: OtpType.email,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('The code was accepted without a user');
    }
    return AuthSessionModel.fromJson(user.toJson());
  }

  @override
  Future<void> saveProfile(SignUpProfile profile) async {
    final phoneWithout966 = profile.phone
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('+966', '');

    await _client.rpc<String>(
      'complete_client_profile',
      params: {
        'p_full_name': profile.fullName,
        'p_national_id': profile.nationalId,
        'p_phone': phoneWithout966,
      },
    );
  }
}
