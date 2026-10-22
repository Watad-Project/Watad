part of 'admin_report_details_bloc.dart';

sealed class AdminReportDetailsEvent {
  const AdminReportDetailsEvent();
}

/// Load the ticket: when the page opens, and on retry.
final class AdminReportDetailsFetched extends AdminReportDetailsEvent {
  const AdminReportDetailsFetched(this.reportId);

  final String reportId;
}

/// «إسناد لي».
final class AdminReportDetailsAssigned extends AdminReportDetailsEvent {
  const AdminReportDetailsAssigned();
}

/// «تم الحل» or «رفض», with the answer the user reads.
final class AdminReportDetailsClosed extends AdminReportDetailsEvent {
  const AdminReportDetailsClosed({required this.status, required this.note});

  /// [ReportStatus.resolved] or [ReportStatus.dismissed].
  final ReportStatus status;
  final String note;
}

/// «حذف الإعلان», after the admin confirmed and gave a reason.
final class AdminReportDetailsListingRemoved extends AdminReportDetailsEvent {
  const AdminReportDetailsListingRemoved({
    required this.itemId,
    required this.reason,
  });

  final String itemId;
  final String reason;
}

/// «إيقاف المستخدم», after the admin confirmed and gave a reason.
final class AdminReportDetailsUserSuspended extends AdminReportDetailsEvent {
  const AdminReportDetailsUserSuspended({
    required this.userId,
    required this.reason,
  });

  final String userId;
  final String reason;
}
