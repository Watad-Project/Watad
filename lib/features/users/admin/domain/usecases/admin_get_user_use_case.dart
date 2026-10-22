import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// One user, for their page; the parameter is their id.
class AdminGetUserUseCase implements UseCase<AdminUser, String> {
  const AdminGetUserUseCase(this._repository);

  final AdminUsersRepository _repository;

  @override
  Future<Result<AdminUser>> call(String params) => _repository.getUser(params);
}
