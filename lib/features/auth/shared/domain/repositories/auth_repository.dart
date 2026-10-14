import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

/// Signing in and registration operations.
abstract interface class AuthRepository {
  /// Emails a sign-in code to the account with this [email]. It never
  /// creates an account: the sign-up screens do.
  Future<Result<void>> sendOtp({required String email});

  /// Checks the [token] sent to [email] and signs the user in.
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  });

  /// Checks whether [email] is already registered in the system.
  Future<Result<bool>> isEmailRegistered(String email);

  /// Saves the business registration data.
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data);
}
