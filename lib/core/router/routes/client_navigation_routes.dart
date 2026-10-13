/// The routes of lib/features/navigation/client/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
///
/// To open one of the client's tabs from a page, pass its first page's route
/// name as `tab`:
/// `context.goNamed(ClientNavigationRoutes.navigationName, queryParameters: {'tab': …Name})`.
abstract final class ClientNavigationRoutes {
  static const String navigationName = 'client-navigation';
  static const String navigationPath = '/client/navigation';
}
