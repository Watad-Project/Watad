import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';

abstract interface class AuthRepository {
  Future<Result<bool>> isEmailRegistered(String email);

  Future<Result<void>> sendSignUpOtp(String email);

  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params);

  Future<Result<void>> saveProfile(SignUpProfile profile);
}
