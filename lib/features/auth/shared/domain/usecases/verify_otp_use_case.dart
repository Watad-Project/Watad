import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

/// Parameters for verifying an email OTP.
class VerifyOtpParams {
  const VerifyOtpParams({required this.email, required this.token});

  final String email;
  final String token;
}

/// Verifies the OTP token for an email and returns the authenticated session.
class VerifyOtpUseCase implements UseCase<AuthSession, VerifyOtpParams> {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  static const int requiredOtpLength = 4;
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$",
  );

  @override
  Future<Result<AuthSession>> call(VerifyOtpParams params) async {
    final email = params.email.trim();
    final token = params.token.trim();

    if (email.isEmpty) {
      return const Failed(ValidationFailure('auth.email_required_error'));
    }
    if (!_emailRegExp.hasMatch(email)) {
      return const Failed(ValidationFailure('auth.invalid_email_error'));
    }
    if (token.isEmpty) {
      return const Failed(ValidationFailure('auth.otp_required_error'));
    }
    if (token.length < requiredOtpLength) {
      return const Failed(ValidationFailure('auth.invalid_otp_error'));
    }

    return _repository.verifyOtp(email: email, token: token);
  }
}
