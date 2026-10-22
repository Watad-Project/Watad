import 'package:watad/core/enums/report_status.dart';

/// Closes a ticket without acting on its target: resolved («تم الحل») or
/// dismissed («رفض»), with the answer the user reads.
class AdminReportClosure {
  const AdminReportClosure({
    required this.reportId,
    required this.status,
    required this.note,
  });

  /// The most the database keeps of a note.
  static const int maxNoteLength = 5000;

  final String reportId;

  /// [ReportStatus.resolved] or [ReportStatus.dismissed].
  final ReportStatus status;

  /// Shown to the user in their own list (`v_my_help_reports`).
  final String note;
}
