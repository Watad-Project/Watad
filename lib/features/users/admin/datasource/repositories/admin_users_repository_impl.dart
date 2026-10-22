import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/users/admin/datasource/remote/admin_users_remote_data_source.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_counts.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_query.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

class AdminUsersRepositoryImpl implements AdminUsersRepository {
  const AdminUsersRepositoryImpl(this._remote);

  final AdminUsersRemoteDataSource _remote;

  @override
  Future<Result<List<AdminUser>>> getUsers(AdminUsersQuery query) =>
      guardSupabaseCall(() => _remote.getUsers(query));

  @override
  Future<Result<AdminUserCounts>> countUsers(String search) =>
      guardSupabaseCall(
        () async => AdminUserCounts(await _remote.countUsers(search)),
      );

  @override
  Future<Result<AdminUser>> getUser(String userId) =>
      guardSupabaseCall(() => _remote.getUser(userId));

  @override
  Future<Result<void>> setSuspension(
    String userId, {
    required bool suspended,
    String? reason,
  }) => guardSupabaseCall(
    () => _remote.setSuspension(userId, suspended: suspended, reason: reason),
  );

  @override
  Future<Result<void>> setRole(String userId, UserRole role) =>
      guardSupabaseCall(() => _remote.setRole(userId, role));
}
