import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class VerifySignUpOtpUseCase implements UseCase<AuthSession, VerifyOtpParams> {
  const VerifySignUpOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(VerifyOtpParams params) async {
    final token = params.token.trim();
    if (token.length != 6) {
      return const Failed(ValidationFailure('validation.otp_invalid'));
    }
    return _repository.verifySignUpOtp(params);
  }
}
