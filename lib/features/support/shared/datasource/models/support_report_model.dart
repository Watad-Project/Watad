import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';

class SupportReportModel extends SupportReport {
  const SupportReportModel({
    required super.id,
    required super.type,
    required super.description,
    required super.status,
    required super.createdAt,
    super.resolutionNote,
    super.targetKind,
    super.resolvedAt,
  });

  /// Maps the `v_my_help_reports` columns selected in
  /// SupportRemoteDataSourceImpl.
  factory SupportReportModel.fromJson(Map<String, dynamic> json) {
    final resolvedAt = json['resolved_at'] as String?;
    final note = (json['resolution_note'] as String?)?.trim();
    return SupportReportModel(
      id: json['id'] as String,
      type: ReportType.fromJson(json['report_type'] as String),
      description: json['description'] as String? ?? '',
      status: ReportStatus.fromJson(json['status'] as String),
      resolutionNote: note == null || note.isEmpty ? null : note,
      targetKind: SupportTargetKind.named(json['target_type'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: resolvedAt == null ? null : DateTime.parse(resolvedAt),
    );
  }
}
