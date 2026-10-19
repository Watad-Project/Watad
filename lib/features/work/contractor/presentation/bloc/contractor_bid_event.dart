part of 'contractor_bid_bloc.dart';

sealed class ContractorBidEvent {
  const ContractorBidEvent();
}

final class ContractorBidStarted extends ContractorBidEvent {
  const ContractorBidStarted(this.projectId);

  final String projectId;
}

final class ContractorBidSubmitted extends ContractorBidEvent {
  const ContractorBidSubmitted({
    required this.amountText,
    required this.message,
  });

  final String amountText;
  final String message;
}

final class ContractorBidWithdrawn extends ContractorBidEvent {
  const ContractorBidWithdrawn();
}
