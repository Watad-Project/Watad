import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorGetBidDetailsUseCase
    implements UseCase<ContractorBidDetails, String> {
  const ContractorGetBidDetailsUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<ContractorBidDetails>> call(String projectId) =>
      _repository.getBidDetails(projectId);
}
