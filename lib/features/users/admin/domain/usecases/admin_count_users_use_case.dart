import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_counts.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// The number on each chip; the parameter is the search.
class AdminCountUsersUseCase implements UseCase<AdminUserCounts, String> {
  const AdminCountUsersUseCase(this._repository);

  final AdminUsersRepository _repository;

  @override
  Future<Result<AdminUserCounts>> call(String params) =>
      _repository.countUsers(params.trim());
}
