import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';

/// A report a user sent, as an admin sees it: a `v_admin_help_reports` row.
class AdminReport {
  const AdminReport({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.target,
    this.targetId,
    this.reporterName,
    this.targetUserId,
    this.targetUserName,
  });

  final String id;
  final ReportType type;

  /// Open or in review: closed reports leave the list.
  final ReportStatus status;

  /// What was reported, and its id (e.g. the listing's id). Null when the
  /// report names no target.
  final AdminReportTarget? target;
  final String? targetId;

  final String? reporterName;

  /// The reported user, only when the report is about a user.
  final String? targetUserId;
  final String? targetUserName;

  /// When the report was sent (UTC).
  final DateTime createdAt;

  /// The listing «حذف الإعلان» removes, when a listing was reported.
  String? get listingId =>
      target == AdminReportTarget.marketplaceItem ? targetId : null;
}
