import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorGetMyContractsUseCase
    implements UseCase<List<ContractorContractProject>, NoParams> {
  const ContractorGetMyContractsUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<List<ContractorContractProject>>> call(NoParams params) =>
      _repository.getMyContracts();
}
