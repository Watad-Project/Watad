import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<void>> sendOtp({
    required String email,
    bool shouldCreateUser = false,
  }) => guardSupabaseCall(
    () => _remote.sendOtp(email: email, shouldCreateUser: shouldCreateUser),
  );

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) => guardSupabaseCall(() => _remote.verifyOtp(email: email, token: token));

  @override
  Future<Result<void>> sendSignUpOtp(String email) =>
      guardSupabaseCall(() => _remote.sendSignUpOtp(email));

  @override
  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params) =>
      guardSupabaseCall(() => _remote.verifySignUpOtp(params));

  @override
  Future<Result<String>> saveProfile(SignUpProfile profile) =>
      guardSupabaseCall(() => _remote.saveProfile(profile));

  @override
  Future<Result<void>> signOut() => guardSupabaseCall(_remote.signOut);

  @override
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data) =>
      guardSupabaseCall(() => _remote.saveBusinessSignUp(data));
}
