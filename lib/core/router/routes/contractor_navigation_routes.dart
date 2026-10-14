/// The routes of lib/features/navigation/contractor/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
///
/// To open one of the contractor's tabs from a page, pass its first page's route
/// name as `tab`:
/// `context.goNamed(ContractorNavigationRoutes.navigationName, queryParameters: {'tab': …Name})`.
abstract final class ContractorNavigationRoutes {
  static const String navigationName = 'contractor-navigation';
  static const String navigationPath = '/contractor/navigation';
}
