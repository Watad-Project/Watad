import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/email_otp.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

/// Checks a sign-in code and signs the user in.
///
/// Only the code is checked here: its email was checked when the code was
/// sent, and a new email needs a new code.
class VerifyOtpUseCase implements UseCase<AuthSession, EmailOtp> {
  const VerifyOtpUseCase(this._repository);

  /// The digits of a Supabase email code. The login page shows this many
  /// boxes; change it here only together with the Supabase setting.
  static const int codeLength = 6;

  final AuthRepository _repository;

  static final RegExp _code = RegExp('^[0-9]{$codeLength}\$');

  @override
  Future<Result<AuthSession>> call(EmailOtp params) async {
    final token = params.token.trim();
    if (token.isEmpty) {
      return const Failed(ValidationFailure('auth.otp_required_error'));
    }
    if (!_code.hasMatch(token)) {
      return const Failed(ValidationFailure('auth.invalid_otp_error'));
    }
    return _repository.verifyOtp(email: params.email.trim(), token: token);
  }
}
