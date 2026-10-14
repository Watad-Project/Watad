import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

/// Emails a sign-in code to an address, once it is a valid one.
class SendOtpUseCase implements UseCase<void, String> {
  const SendOtpUseCase(this._repository);

  final AuthRepository _repository;

  static final RegExp _email = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$",
  );

  @override
  Future<Result<void>> call(String params) async {
    final email = params.trim();
    if (email.isEmpty) {
      return const Failed(ValidationFailure('auth.email_required_error'));
    }
    if (!_email.hasMatch(email)) {
      return const Failed(ValidationFailure('auth.invalid_email_error'));
    }
    return _repository.sendOtp(email: email);
  }
}
