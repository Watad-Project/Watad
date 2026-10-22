import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

/// «إغلاق» (resolved) or «رفض البلاغ» (dismissed).
class AdminCloseReportUseCase implements UseCase<void, AdminReportClosure> {
  const AdminCloseReportUseCase(this._repository);

  final AdminReportsRepository _repository;

  @override
  Future<Result<void>> call(AdminReportClosure params) async {
    if (params.status != ReportStatus.resolved &&
        params.status != ReportStatus.dismissed) {
      return const Failed(ValidationFailure('validation.invalid'));
    }
    return _repository.close(params.reportId, params.status);
  }
}
