import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

/// The reports still to handle, newest first.
class AdminGetReportsUseCase implements UseCase<List<AdminReport>, NoParams> {
  const AdminGetReportsUseCase(this._repository);

  final AdminReportsRepository _repository;

  @override
  Future<Result<List<AdminReport>>> call(NoParams params) =>
      _repository.getOpenReports();
}
