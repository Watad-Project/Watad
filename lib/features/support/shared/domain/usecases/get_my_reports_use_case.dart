import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';
import 'package:watad/features/support/shared/domain/repositories/support_repository.dart';

class GetMyReportsUseCase implements UseCase<List<SupportReport>, NoParams> {
  const GetMyReportsUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Result<List<SupportReport>>> call(NoParams params) =>
      _repository.getMyReports();
}
