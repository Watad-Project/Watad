import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';

abstract interface class AuthRemoteDataSource {
  /// Signs up a new user with [email] and optional [password], [phone], or [data].
  Future<AuthSessionModel?> signUp({
    required String email,
    String? password,
    String? phone,
    Map<String, dynamic>? data,
  });

  /// Emails a sign-in or sign-up code to the account with this [email].
  Future<void> sendOtp({required String email, bool shouldCreateUser = false});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  });

  Future<void> sendSignUpOtp(String email);

  Future<AuthSessionModel> verifySignUpOtp(VerifyOtpParams params);

  Future<String> saveProfile(SignUpProfile profile);

  Future<void> signOut();

  /// Saves the business signup data.
  Future<void> saveBusinessSignUp(BusinessSignUp data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthSessionModel?> signUp({
    required String email,
    String? password,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password ?? '',
      phone: phone,
      data: data,
    );
    final user = response.user;
    if (user == null) {
      return null;
    }
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      );
    }
    return AuthSessionModel.fromJson(user.toJson());
  }

  @override
  Future<void> sendOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
    );
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
  Future<String> saveProfile(SignUpProfile profile) async {
    final phoneWithout966 = profile.phone
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('+966', '');

    final result = await _client.rpc<String>(
      'complete_client_profile',
      params: {
        'p_full_name': profile.fullName,
        'p_national_id': profile.nationalId,
        'p_phone': phoneWithout966,
      },
    );
    return result;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> saveBusinessSignUp(BusinessSignUp data) async {
    await _client.from('businesses').insert({
      'company_name': data.companyName,
      'cr_number': data.crNumber,
      'specialized_field': data.specializedField,
    });
  }
}
