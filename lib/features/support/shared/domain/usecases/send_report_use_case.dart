import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/repositories/support_repository.dart';

/// Sends a report with its description trimmed, after the database's own
/// rule: 5 to 5000 characters.
class SendReportUseCase implements UseCase<void, SupportNewReport> {
  const SendReportUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Result<void>> call(SupportNewReport report) {
    final description = report.description.trim();
    if (description.length < SupportNewReport.minLength) {
      return Future.value(
        const Failed(ValidationFailure('support.error_description_short')),
      );
    }
    if (description.length > SupportNewReport.maxLength) {
      return Future.value(
        const Failed(ValidationFailure('support.error_description_long')),
      );
    }
    return _repository.sendReport(
      SupportNewReport(
        type: report.type,
        description: description,
        target: report.target,
      ),
    );
  }
}
