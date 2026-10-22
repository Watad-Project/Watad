/// The routes of lib/features/users/admin/. Any feature navigates to them
/// with these names (APP_ARCHITECTURE.md §11).
abstract final class AdminUsersRoutes {
  static const String usersName = 'admin-users';
  static const String usersPath = '/admin/users';
  static const String userDetailsName = 'admin-user-details';
  static const String userDetailsPath = '/admin/users/:userId';
}
