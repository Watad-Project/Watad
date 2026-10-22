import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';

abstract interface class AdminReportsRepository {
  /// Every ticket, closed ones included, newest first.
  Future<Result<List<AdminReport>>> getReports();

  /// One ticket; [NotFoundFailure] when there is none with [reportId].
  Future<Result<AdminReport>> getReport(String reportId);

  /// Assigns the ticket to the signed-in admin; an open ticket moves to in
  /// review.
  Future<Result<void>> assignToMe(String reportId);

  /// Hides the listing and cancels its unpaid orders. The seller reads
  /// [reason].
  Future<Result<void>> removeListing(String itemId, String reason);

  /// The user reads [reason].
  Future<Result<void>> suspendUser(String userId, String reason);

  /// [status] is [ReportStatus.resolved] or [ReportStatus.dismissed]; the
  /// user who sent it reads [note].
  Future<Result<void>> close(
    String reportId,
    ReportStatus status, {
    required String note,
  });
}
