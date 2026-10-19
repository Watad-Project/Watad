import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';

class ContractorEditOfferParams {
  const ContractorEditOfferParams({
    required this.offerId,
    required this.amount,
    required this.message,
  });

  final String offerId;
  final Money amount;
  final String message;
}

class ContractorEditOfferUseCase
    implements UseCase<void, ContractorEditOfferParams> {
  const ContractorEditOfferUseCase(this._repository);

  final ContractorWorkRepository _repository;

  @override
  Future<Result<void>> call(ContractorEditOfferParams params) async {
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
    return _repository.editOffer(
      offerId: params.offerId,
      amount: params.amount,
      message: trimmedMessage,
    );
  }
}
