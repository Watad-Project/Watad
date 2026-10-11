import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class CheckEmailRegisteredUseCase implements UseCase<bool, String> {
  const CheckEmailRegisteredUseCase(this._repository);

  final AuthRepository _repository;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  @override
  Future<Result<bool>> call(String params) async {
    final trimmed = params.trim();
    if (trimmed.isEmpty) {
      return const Failed(ValidationFailure('validation.email_required'));
    }
    if (!_emailRegExp.hasMatch(trimmed)) {
      return const Failed(ValidationFailure('validation.email_invalid'));
    }
    return _repository.isEmailRegistered(trimmed);
  }
}
