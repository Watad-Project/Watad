import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/admin_reports_injection.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

/// A hand-written [AdminReportsRepository]: it answers with the results you
/// set and records every call, in order (APP_ARCHITECTURE.md §16).
class FakeAdminReportsRepository implements AdminReportsRepository {
  Result<List<AdminReport>> reportsResult = const Success([]);
  Result<void> actionResult = const Success(null);

  /// Answers [close]; [actionResult] unless set.
  Result<void>? closeResult;

  /// Every action, e.g. `assign r-1`, `remove i-1: reason`,
  /// `close r-1 resolved: reason`.
  final List<String> calls = [];

  /// How many times the reports were read.
  int reads = 0;

  @override
  Future<Result<List<AdminReport>>> getOpenReports() async {
    reads++;
    return reportsResult;
  }

  @override
  Future<Result<void>> assignToMe(String reportId) async {
    calls.add('assign $reportId');
    return actionResult;
  }

  @override
  Future<Result<void>> removeListing(String itemId, String reason) async {
    calls.add('remove $itemId: $reason');
    return actionResult;
  }

  @override
  Future<Result<void>> suspendUser(String userId, String reason) async {
    calls.add('suspend $userId: $reason');
    return actionResult;
  }

  @override
  Future<Result<void>> close(
    String reportId,
    ReportStatus status, {
    String? note,
  }) async {
    calls.add('close $reportId ${status.toJson()}: $note');
    return closeResult ?? actionResult;
  }
}

/// For tests that open the admin's navigation (its «البلاغات» tab) or the
/// reports route: the real registrations, with [repository] in place of
/// Supabase. Reset getIt after the test.
void registerFakeAdminReports(FakeAdminReportsRepository repository) {
  registerAdminReportsDependencies(getIt);
  getIt
    ..unregister<AdminReportsRepository>()
    ..registerSingleton<AdminReportsRepository>(repository);
}
