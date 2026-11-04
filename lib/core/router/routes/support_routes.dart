/// The routes of lib/features/support/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class SupportRoutes {
  /// «المساعدة والدعم»: my reports.
  static const String supportReportsName = 'support-reports';
  static const String supportReportsPath = '/support';

  /// «بلاغ جديد». To report something, pass the query parameters `target`
  /// (`user`, `project`, `item`, `order`, `review` or `message`) and `id`
  /// (its id).
  static const String supportNewReportName = 'support-new-report';
  static const String supportNewReportPath = '/support/new';
}
