import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';

/// Abstract contract for authentication operations.
abstract interface class AuthRepository {
  /// Sends an email verification code (OTP) to the given [email].
  Future<Result<void>> sendOtp({required String email});

  /// Verifies the [token] sent to [email] and returns the authenticated session.
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  });
}
