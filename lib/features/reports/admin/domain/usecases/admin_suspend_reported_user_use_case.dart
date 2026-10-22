import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';

/// «إيقاف المستخدم»: suspends the reported user, then resolves the report
/// with the same reason.
class AdminSuspendReportedUserUseCase
    implements UseCase<void, AdminReportDecision> {
  const AdminSuspendReportedUserUseCase(this._repository);

  final AdminReportsRepository _repository;

  @override
  Future<Result<void>> call(AdminReportDecision params) async {
    final reason = params.reason.trim();
    if (reason.isEmpty) {
      return const Failed(ValidationFailure('common.reason_required'));
    }
    // It is also the ticket's closing note.
    if (reason.length > AdminReportClosure.maxNoteLength) {
      return const Failed(ValidationFailure('reports.note_too_long'));
    }
    final suspended = await _repository.suspendUser(params.subjectId, reason);
    if (suspended is Failed<void>) return suspended;
    return _repository.close(
      params.reportId,
      ReportStatus.resolved,
      note: reason,
    );
  }
}
