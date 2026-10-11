import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class SendSignUpOtpUseCase implements UseCase<void, String> {
  const SendSignUpOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) async {
    final email = params.trim();
    if (email.isEmpty) {
      return const Failed(ValidationFailure('validation.email_required'));
    }
    return _repository.sendSignUpOtp(email);
  }
}
