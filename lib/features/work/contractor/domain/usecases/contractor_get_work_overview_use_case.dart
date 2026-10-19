import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorGetWorkOverviewUseCase
    implements UseCase<ContractorWorkOverview, NoParams> {
  const ContractorGetWorkOverviewUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<ContractorWorkOverview>> call(NoParams params) async {
    final result = await _repository.getWorkOverview();
    return switch (result) {
      Success(:final data) => Success(
        ContractorWorkOverview(
          openProjects: data.openProjects
              .where((project) => !project.isMine)
              .toList(growable: false),
          contracts: data.contracts,
          contractsCount: data.contractsCount,
        ),
      ),
      Failed(:final failure) => Failed(failure),
    };
  }
}
