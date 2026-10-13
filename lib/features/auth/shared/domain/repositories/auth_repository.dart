import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';

/// Signing in and signing up with email and OTP.
abstract interface class AuthRepository {
  /// Emails a sign-in code to the account with this [email]. It never
  /// creates an account: the sign-up screens do.
  Future<Result<void>> sendOtp({required String email});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  });

  Future<Result<bool>> isEmailRegistered(String email);

  Future<Result<void>> sendSignUpOtp(String email);

  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params);

  Future<Result<void>> saveProfile(SignUpProfile profile);
}
