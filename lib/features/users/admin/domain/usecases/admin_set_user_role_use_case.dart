import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_role_change.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// «تعيين كمشرف» / «إزالة صلاحية المشرف», refusing first what the database
/// would refuse, with its own message.
class AdminSetUserRoleUseCase implements UseCase<void, AdminUserRoleChange> {
  const AdminSetUserRoleUseCase(this._repository);

  final AdminUsersRepository _repository;

  @override
  Future<Result<void>> call(AdminUserRoleChange params) async {
    final user = params.user;
    if (user.isDeleted) {
      return const Failed(ValidationFailure('users.error_closed'));
    }
    if (user.isMe && params.role != UserRole.admin) {
      return const Failed(ValidationFailure('users.error_remove_own_admin'));
    }
    return _repository.setRole(user.id, params.role);
  }
}
