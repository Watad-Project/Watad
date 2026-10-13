/// The routes of lib/features/navigation/admin/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
///
/// To open one of the admin's tabs from a page, pass its first page's route
/// name as `tab`:
/// `context.goNamed(AdminNavigationRoutes.navigationName, queryParameters: {'tab': …Name})`.
abstract final class AdminNavigationRoutes {
  static const String navigationName = 'admin-navigation';
  static const String navigationPath = '/admin/navigation';
}
