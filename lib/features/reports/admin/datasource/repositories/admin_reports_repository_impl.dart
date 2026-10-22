import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/reports/admin/datasource/remote/admin_reports_remote_data_source.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

class AdminReportsRepositoryImpl implements AdminReportsRepository {
  const AdminReportsRepositoryImpl(this._remote);

  final AdminReportsRemoteDataSource _remote;

  @override
  Future<Result<List<AdminReport>>> getOpenReports() =>
      guardSupabaseCall(_remote.getOpenReports);

  @override
  Future<Result<void>> assignToMe(String reportId) =>
      guardSupabaseCall(() => _remote.assignToMe(reportId));

  @override
  Future<Result<void>> removeListing(String itemId, String reason) =>
      guardSupabaseCall(() => _remote.removeListing(itemId, reason));

  @override
  Future<Result<void>> suspendUser(String userId, String reason) =>
      guardSupabaseCall(() => _remote.suspendUser(userId, reason));

  @override
  Future<Result<void>> close(
    String reportId,
    ReportStatus status, {
    String? note,
  }) => guardSupabaseCall(() => _remote.close(reportId, status, note: note));
}
