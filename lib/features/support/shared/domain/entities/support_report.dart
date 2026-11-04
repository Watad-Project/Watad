import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';

/// One of my reports: a `v_my_help_reports` row.
class SupportReport {
  const SupportReport({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolutionNote,
    this.targetKind,
    this.resolvedAt,
  });

  final String id;
  final ReportType type;
  final String description;
  final ReportStatus status;

  /// The admin's answer, once they resolved or dismissed it.
  final String? resolutionNote;
  final SupportTargetKind? targetKind;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}
