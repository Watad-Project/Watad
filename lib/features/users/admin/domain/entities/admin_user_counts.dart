import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';

/// The number on each chip, for the current search.
class AdminUserCounts {
  const AdminUserCounts(this.byFilter);

  final Map<AdminUsersFilter, int> byFilter;

  int of(AdminUsersFilter filter) => byFilter[filter] ?? 0;
}
