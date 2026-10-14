import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

/// Signing in and registration operations.
abstract interface class AuthRepository {
  /// Emails a sign-in or sign-up code to the account with this [email].
  Future<Result<void>> sendOtp({
    required String email,
    bool shouldCreateUser = false,
  });

  /// Checks the [token] sent to [email] and signs the user in.
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  });

  /// Saves the business registration data.
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data);
}
