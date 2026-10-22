import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_counts.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_query.dart';

abstract interface class AdminUsersRepository {
  /// One page of users, newest first.
  Future<Result<List<AdminUser>>> getUsers(AdminUsersQuery query);

  /// How many users each chip has, for [search].
  Future<Result<AdminUserCounts>> countUsers(String search);

  /// One user; [NotFoundFailure] when there is none with [userId].
  Future<Result<AdminUser>> getUser(String userId);

  /// Suspends the user, who reads [reason], or lifts their suspension.
  Future<Result<void>> setSuspension(
    String userId, {
    required bool suspended,
    String? reason,
  });

  Future<Result<void>> setRole(String userId, UserRole role);
}
