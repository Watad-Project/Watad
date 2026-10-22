import 'package:watad/core/enums/report_status.dart';

/// Closes a report without acting on its target: resolved («إغلاق») or
/// dismissed («رفض البلاغ»).
class AdminReportClosure {
  const AdminReportClosure({required this.reportId, required this.status});

  final String reportId;

  /// [ReportStatus.resolved] or [ReportStatus.dismissed].
  final ReportStatus status;
}
