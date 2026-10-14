import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

abstract interface class AuthRemoteDataSource {
  /// Emails a sign-in or sign-up code to the account with this [email].
  Future<void> sendOtp({required String email, bool shouldCreateUser = false});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  });

  /// Saves the business signup data.
  Future<void> saveBusinessSignUp(BusinessSignUp data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

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
  Future<void> saveBusinessSignUp(BusinessSignUp data) async {
    await _client.from('businesses').insert({
      'company_name': data.companyName,
      'cr_number': data.crNumber,
      'specialized_field': data.specializedField,
    });
  }
}
