import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';

abstract interface class AuthRemoteDataSource {
  Future<bool> isEmailRegistered(String email);

  Future<void> sendSignUpOtp(String email);

  Future<AuthSessionModel> verifySignUpOtp(VerifyOtpParams params);

  Future<void> saveProfile(SignUpProfile profile);
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
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': profile.fullName,
          'national_id': profile.nationalId,
          'phone': profile.phone,
          'role': profile.role,
        },
      ),
    );
    await _client.from('users').update({'full_name': profile.fullName});
  }
}
