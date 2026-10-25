import 'package:watad/core/enums/report_status.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';

/// The status chips of the tickets list: «مفتوحة», «قيد المراجعة»,
/// «مسندة لي» and «مغلقة».
enum AdminReportsStatusFilter {
  open,
  inReview,
  assignedToMe,
  closed;

  bool matches(AdminReport report) => switch (this) {
    open => report.status == ReportStatus.open,
    inReview => report.status == ReportStatus.inReview,
    // Only the ones still to handle: a closed ticket moves to «مغلقة».
    assignedToMe => report.isAssignedToMe && !report.isClosed,
    closed => report.isClosed,
  };
}
