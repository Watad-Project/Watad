part of 'contractor_bid_bloc.dart';

sealed class ContractorBidState {
  const ContractorBidState();
}

final class ContractorBidInitial extends ContractorBidState {
  const ContractorBidInitial();
}

final class ContractorBidLoadInProgress extends ContractorBidState {
  const ContractorBidLoadInProgress();
}

final class ContractorBidLoadFailure extends ContractorBidState {
  const ContractorBidLoadFailure(this.failure);

  final Failure failure;
}

final class ContractorBidReady extends ContractorBidState {
  const ContractorBidReady({
    required this.details,
    this.isSubmitting = false,
    this.isWithdrawing = false,
    this.amountErrorKey,
    this.messageErrorKey,
    this.actionFailure,
    this.completedMessageKey,
  });

  final ContractorBidDetails details;
  final bool isSubmitting;
  final bool isWithdrawing;
  final String? amountErrorKey;
  final String? messageErrorKey;
  final Failure? actionFailure;
  final String? completedMessageKey;
}
