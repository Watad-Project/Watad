import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';

/// A ticket a user sent (a support request or a report), as an admin sees
/// it: a `v_admin_help_reports` row.
class AdminReport {
  const AdminReport({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.target,
    this.targetId,
    this.evidence,
    this.reporterName,
    this.targetUserId,
    this.targetUserName,
    this.assignedAdminName,
    this.isAssignedToMe = false,
    this.resolutionNote,
    this.resolvedAt,
  });

  final String id;
  final ReportType type;
  final ReportStatus status;

  /// What the user wrote.
  final String description;

  /// What was reported, and its id (e.g. the listing's id). Null when the
  /// ticket names no target.
  final AdminReportTarget? target;
  final String? targetId;

  /// The copy of the reported message or review saved when the ticket was
  /// sent, so editing or deleting it later changes nothing.
  final String? evidence;

  final String? reporterName;

  /// The reported user, only when the ticket is about a user.
  final String? targetUserId;
  final String? targetUserName;

  /// The admin handling it; null while nobody took it.
  final String? assignedAdminName;

  /// It is assigned to the signed-in admin.
  final bool isAssignedToMe;

  /// The answer the user reads in their own list, once it is closed.
  final String? resolutionNote;

  /// When the ticket was sent, and when it was closed (UTC).
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// Resolved or dismissed: the database refuses any further action.
  bool get isClosed =>
      status == ReportStatus.resolved || status == ReportStatus.dismissed;

  /// The listing «حذف الإعلان» removes, when a listing was reported.
  String? get listingId =>
      target == AdminReportTarget.marketplaceItem ? targetId : null;
}
