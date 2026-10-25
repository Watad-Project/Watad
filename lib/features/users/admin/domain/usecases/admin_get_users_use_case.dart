import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_query.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// One page of the users list.
class AdminGetUsersUseCase
    implements UseCase<List<AdminUser>, AdminUsersQuery> {
  const AdminGetUsersUseCase(this._repository);

  final AdminUsersRepository _repository;

  @override
  Future<Result<List<AdminUser>>> call(AdminUsersQuery params) =>
      _repository.getUsers(params);
}
