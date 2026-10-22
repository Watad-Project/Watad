import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';

class AdminReportModel extends AdminReport {
  const AdminReportModel({
    required super.id,
    required super.type,
    required super.status,
    required super.createdAt,
    super.description,
    super.target,
    super.targetId,
    super.evidence,
    super.reporterName,
    super.targetUserId,
    super.targetUserName,
    super.assignedAdminName,
    super.isAssignedToMe,
    super.resolutionNote,
    super.resolvedAt,
  });

  /// Maps the columns selected in AdminReportsRemoteDataSourceImpl, plus
  /// `assigned_to_me`, which the data source adds: whether
  /// `assigned_admin_id` is the signed-in admin.
  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    final resolvedAt = json['resolved_at'] as String?;
    return AdminReportModel(
      id: json['id'] as String,
      type: ReportType.fromJson(json['report_type'] as String),
      status: ReportStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String? ?? '',
      target: switch (json['target_type'] as String?) {
        'user' => AdminReportTarget.user,
        'project' => AdminReportTarget.project,
        'marketplace_item' => AdminReportTarget.marketplaceItem,
        'order' => AdminReportTarget.order,
        'review' => AdminReportTarget.review,
        'message' => AdminReportTarget.message,
        _ => null,
      },
      targetId: json['target_id'] as String?,
      evidence: json['evidence_snapshot'] as String?,
      reporterName: json['reporter_name'] as String?,
      targetUserId: json['target_user_id'] as String?,
      targetUserName: json['target_user_name'] as String?,
      assignedAdminName: json['assigned_admin_name'] as String?,
      isAssignedToMe: json['assigned_to_me'] as bool? ?? false,
      resolutionNote: json['resolution_note'] as String?,
      resolvedAt: resolvedAt == null ? null : DateTime.parse(resolvedAt),
    );
  }
}
