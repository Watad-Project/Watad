import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorSubmitOfferParams {
  const ContractorSubmitOfferParams({
    required this.projectId,
    required this.amount,
    required this.message,
  });

  final String projectId;
  final Money amount;
  final String message;
}

class ContractorSubmitOfferUseCase
    implements UseCase<void, ContractorSubmitOfferParams> {
  const ContractorSubmitOfferUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<void>> call(ContractorSubmitOfferParams params) async {
    if (params.amount.halalas <= 0) {
      return const Failed(
        ValidationFailure('work.contractor.bid_amount_invalid'),
      );
    }
    final trimmedMessage = params.message.trim();
    if (trimmedMessage.isEmpty) {
      return const Failed(
        ValidationFailure('work.contractor.bid_message_required'),
      );
    }
    return _repository.submitOffer(
      projectId: params.projectId,
      amount: params.amount,
      message: trimmedMessage,
    );
  }
}
