import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

/// One ticket, for its details page; the parameter is its id.
class AdminGetReportUseCase implements UseCase<AdminReport, String> {
  const AdminGetReportUseCase(this._repository);

  final AdminReportsRepository _repository;

  @override
  Future<Result<AdminReport>> call(String params) =>
      _repository.getReport(params);
}
