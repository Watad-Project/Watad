import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorGetWorkOverviewUseCase
    implements UseCase<ContractorWorkOverview, ContractorWorkFilter> {
  const ContractorGetWorkOverviewUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<ContractorWorkOverview>> call([
    ContractorWorkFilter params = const ContractorWorkFilter(),
  ]) async {
    final result = await _repository.getWorkOverview(filter: params);
    return switch (result) {
      Success(:final data) => Success(
        ContractorWorkOverview(
          openProjects: params.apply(data.openProjects),
          contracts: data.contracts,
          contractsCount: data.contractsCount,
        ),
      ),
      Failed(:final failure) => Failed(failure),
    };
  }
}
