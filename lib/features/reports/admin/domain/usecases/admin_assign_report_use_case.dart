import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

/// «إسناد لي»; the parameter is the report id.
class AdminAssignReportUseCase implements UseCase<void, String> {
  const AdminAssignReportUseCase(this._repository);

  final AdminReportsRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.assignToMe(params);
}
