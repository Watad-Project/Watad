part of 'admin_reports_bloc.dart';

sealed class AdminReportsEvent {
  const AdminReportsEvent();
}

/// Load the tickets: at the start, on pull to refresh and back from a
/// ticket's details.
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

/// «إغلاق» or «رفض البلاغ», after the admin wrote the answer.
final class AdminReportClosed extends AdminReportsEvent {
  const AdminReportClosed(this.closure);

  final AdminReportClosure closure;
}

/// A status chip was picked.
final class AdminReportsStatusFilterChanged extends AdminReportsEvent {
  const AdminReportsStatusFilterChanged(this.filter);

  final AdminReportsStatusFilter filter;
}

/// All, support or moderation was picked.
final class AdminReportsTypeFilterChanged extends AdminReportsEvent {
  const AdminReportsTypeFilterChanged(this.filter);

  final AdminReportsTypeFilter filter;
}
