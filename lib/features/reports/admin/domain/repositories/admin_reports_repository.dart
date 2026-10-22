import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';

abstract interface class AdminReportsRepository {
  /// Open and in-review reports, newest first.
  Future<Result<List<AdminReport>>> getOpenReports();

  /// Assigns the report to the signed-in admin; an open report moves to in
  /// review.
  Future<Result<void>> assignToMe(String reportId);

  /// Hides the listing and cancels its unpaid orders. The seller reads
  /// [reason].
  Future<Result<void>> removeListing(String itemId, String reason);

  /// The user reads [reason].
  Future<Result<void>> suspendUser(String userId, String reason);

  /// [status] is [ReportStatus.resolved] or [ReportStatus.dismissed].
  Future<Result<void>> close(
    String reportId,
    ReportStatus status, {
    String? note,
  });
}
