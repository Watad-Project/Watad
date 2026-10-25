import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// «رفع الإيقاف»; the parameter is the suspended user.
class AdminUnsuspendUserUseCase implements UseCase<void, AdminUser> {
  const AdminUnsuspendUserUseCase(this._repository);

  final AdminUsersRepository _repository;

  @override
  Future<Result<void>> call(AdminUser params) async {
    if (params.isDeleted) {
      return const Failed(ValidationFailure('users.error_closed'));
    }
    if (!params.isSuspended) {
      return const Failed(ValidationFailure('users.error_not_suspended'));
    }
    return _repository.setSuspension(params.id, suspended: false);
  }
}
