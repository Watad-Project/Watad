import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';

/// One page of the users list: the chip, the search (a name, or a company
/// name for businesses) and where the page starts.
class AdminUsersQuery {
  const AdminUsersQuery({
    required this.filter,
    required this.offset,
    required this.limit,
    this.search = '',
  });

  final AdminUsersFilter filter;
  final String search;
  final int offset;
  final int limit;
}
