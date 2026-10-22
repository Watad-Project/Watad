part of 'admin_reports_bloc.dart';

sealed class AdminReportsEvent {
  const AdminReportsEvent();
}

/// Load the reports, at the start and on pull to refresh.
final class AdminReportsFetched extends AdminReportsEvent {
  const AdminReportsFetched();
}

/// «إسناد لي».
final class AdminReportAssigned extends AdminReportsEvent {
  const AdminReportAssigned(this.reportId);

  final String reportId;
}

/// «حذف الإعلان», after the admin confirmed and gave a reason.
final class AdminReportListingRemoved extends AdminReportsEvent {
  const AdminReportListingRemoved(this.decision);

  final AdminReportDecision decision;
}

/// «إيقاف المستخدم», after the admin confirmed and gave a reason.
final class AdminReportUserSuspended extends AdminReportsEvent {
  const AdminReportUserSuspended(this.decision);

  final AdminReportDecision decision;
}

/// «إغلاق» or «رفض البلاغ».
final class AdminReportClosed extends AdminReportsEvent {
  const AdminReportClosed(this.closure);

  final AdminReportClosure closure;
}
