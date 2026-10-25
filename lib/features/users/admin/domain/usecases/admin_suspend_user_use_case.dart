import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_suspension.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// «إيقاف المستخدم». The database refuses the same cases, but with one
/// generic error, so they are told apart here first, each with its own
/// message.
class AdminSuspendUserUseCase implements UseCase<void, AdminUserSuspension> {
  const AdminSuspendUserUseCase(this._repository);

  final AdminUsersRepository _repository;

  @override
  Future<Result<void>> call(AdminUserSuspension params) async {
    final user = params.user;
    final reason = params.reason.trim();
    final refusal = switch (user) {
      _ when user.isDeleted => 'users.error_closed',
      _ when user.isMe => 'users.error_suspend_self',
      _ when user.isAdmin => 'users.error_suspend_admin',
      _ when user.isSuspended => 'users.error_already_suspended',
      _ when reason.isEmpty => 'common.reason_required',
      _ when reason.length > AdminUserSuspension.maxReasonLength =>
        'users.error_reason_too_long',
      _ => null,
    };
    if (refusal != null) return Failed(ValidationFailure(refusal));
    return _repository.setSuspension(user.id, suspended: true, reason: reason);
  }
}
