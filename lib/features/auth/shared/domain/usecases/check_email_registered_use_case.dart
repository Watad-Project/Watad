import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class CheckEmailRegisteredUseCase implements UseCase<bool, String> {
  const CheckEmailRegisteredUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<bool>> call(String params) =>
      _repository.isEmailRegistered(params);
}
