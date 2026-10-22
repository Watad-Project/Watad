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
    super.target,
    super.targetId,
    super.reporterName,
    super.targetUserId,
    super.targetUserName,
  });

  /// Maps the columns selected in AdminReportsRemoteDataSourceImpl.
  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    return AdminReportModel(
      id: json['id'] as String,
      type: ReportType.fromJson(json['report_type'] as String),
      status: ReportStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
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
      reporterName: json['reporter_name'] as String?,
      targetUserId: json['target_user_id'] as String?,
      targetUserName: json['target_user_name'] as String?,
    );
  }
}
