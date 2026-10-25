import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/admin_users_injection.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_counts.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_query.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';

/// A client, online.
final AdminUser fakeClient = AdminUser(
  id: 'u-client',
  name: 'سارة العتيبي',
  role: UserRole.user,
  memberSince: DateTime.utc(2026, 9, 1),
  isOnline: true,
  clientProjectCount: 3,
  email: 'sara@example.com',
  phone: '+966512345678',
  nationalId: '1012345678',
);

/// A business waiting for its license to be verified.
final AdminUser fakeBusiness = AdminUser(
  id: 'u-business',
  name: 'خالد الحربي',
  role: UserRole.user,
  memberSince: DateTime.utc(2026, 8, 20),
  lastSeenAt: DateTime.utc(2026, 10, 1),
  isBusiness: true,
  companyName: 'مقاولات الخبر',
  specialty: 'ترميم',
  businessCity: 'الخبر',
  verificationStatus: VerificationStatus.pending,
  clientProjectCount: 1,
  contractorProjectCount: 2,
  listingCount: 4,
  email: 'khalid@example.com',
);

/// Another admin.
final AdminUser fakeAdmin = AdminUser(
  id: 'u-admin',
  name: 'عمر ملا',
  role: UserRole.admin,
  memberSince: DateTime.utc(2026, 7, 1),
);

/// The admin using the app.
final AdminUser fakeMe = AdminUser(
  id: 'u-me',
  name: 'أمير عظيم',
  role: UserRole.admin,
  memberSince: DateTime.utc(2026, 7, 1),
  isMe: true,
);

/// A suspended client.
final AdminUser fakeSuspended = AdminUser(
  id: 'u-suspended',
  name: 'فهد القحطاني',
  role: UserRole.user,
  memberSince: DateTime.utc(2026, 9, 10),
  isSuspended: true,
  suspensionReason: 'رسائل مسيئة متكررة',
  suspendedAt: DateTime.utc(2026, 10, 20),
  suspendedByName: 'عمر ملا',
  openReportCount: 2,
);

/// A closed account.
final AdminUser fakeClosed = AdminUser(
  id: 'u-closed',
  name: 'حساب محذوف',
  role: UserRole.user,
  memberSince: DateTime.utc(2026, 6, 1),
  isDeleted: true,
);

/// A hand-written [AdminUsersRepository]: it pages, filters and searches
/// [users] like the view would, and records every action
/// (APP_ARCHITECTURE.md §16).
class FakeAdminUsersRepository implements AdminUsersRepository {
  List<AdminUser> users = [
    fakeClient,
    fakeBusiness,
    fakeAdmin,
    fakeMe,
    fakeSuspended,
    fakeClosed,
  ];

  /// Answers [getUsers] instead, when set.
  Result<List<AdminUser>>? usersResult;
  Result<void> actionResult = const Success(null);

  /// Every query and action, e.g. `suspend u-client: سبب`, `role u-x admin`.
  final List<AdminUsersQuery> queries = [];
  final List<String> calls = [];
  int userReads = 0;

  List<AdminUser> _matching(AdminUsersFilter filter, String search) => [
    for (final user in users)
      if (filter.matches(user) &&
          (search.isEmpty ||
              user.name.contains(search) ||
              (user.companyName?.contains(search) ?? false)))
        user,
  ];

  @override
  Future<Result<List<AdminUser>>> getUsers(AdminUsersQuery query) async {
    queries.add(query);
    if (usersResult case final result?) return result;
    return Success(
      _matching(
        query.filter,
        query.search,
      ).skip(query.offset).take(query.limit).toList(),
    );
  }

  @override
  Future<Result<AdminUserCounts>> countUsers(String search) async => Success(
    AdminUserCounts({
      for (final filter in AdminUsersFilter.values)
        filter: _matching(filter, search).length,
    }),
  );

  @override
  Future<Result<AdminUser>> getUser(String userId) async {
    userReads++;
    for (final user in users) {
      if (user.id == userId) return Success(user);
    }
    return const Failed(NotFoundFailure());
  }

  @override
  Future<Result<void>> setSuspension(
    String userId, {
    required bool suspended,
    String? reason,
  }) async {
    calls.add(suspended ? 'suspend $userId: $reason' : 'unsuspend $userId');
    return actionResult;
  }

  @override
  Future<Result<void>> setRole(String userId, UserRole role) async {
    calls.add('role $userId ${role.toJson()}');
    return actionResult;
  }
}

/// For tests that open the users routes, or the dashboard button to them:
/// the real registrations, with [repository] in place of Supabase. Reset
/// getIt after the test.
void registerFakeAdminUsers(FakeAdminUsersRepository repository) {
  registerAdminUsersDependencies(getIt);
  getIt
    ..unregister<AdminUsersRepository>()
    ..registerSingleton<AdminUsersRepository>(repository);
}
