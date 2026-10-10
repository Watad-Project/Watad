import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';

/// Signing in with a code sent by email.
abstract interface class AuthRepository {
  /// Emails a sign-in code to the account with this [email]. It never
  /// creates an account: the sign-up screens do.
  Future<Result<void>> sendOtp({required String email});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  });
}
