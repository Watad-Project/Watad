import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorWithdrawOfferUseCase implements UseCase<void, String> {
  const ContractorWithdrawOfferUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<void>> call(String offerId) async {
    final trimmedId = offerId.trim();
    if (trimmedId.isEmpty) {
      return const Failed(ValidationFailure('validation.invalid'));
    }
    return _repository.withdrawOffer(trimmedId);
  }
}
