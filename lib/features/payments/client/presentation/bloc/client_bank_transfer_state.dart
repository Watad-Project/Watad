part of 'client_bank_transfer_bloc.dart';

enum ClientBankTransferStatus { initial, loading, success, failure }

/// A message to show once, as a translation key.
final class ClientBankTransferMessage {
  const ClientBankTransferMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class ClientBankTransferState {
  const ClientBankTransferState({
    this.status = ClientBankTransferStatus.initial,
    this.selection,
    this.transfer,
    this.failure,
    this.receipt,
    this.isSending = false,
    this.isSent = false,
    this.outcome,
    this.message,
  });

  final ClientBankTransferStatus status;

  /// The tasks the client chose on the previous page.
  final ClientPaymentSelection? selection;
  final ClientBankTransfer? transfer;

  /// Why the page couldn't load.
  final Failure? failure;

  /// The receipt picked, once it passed the checks.
  final ClientReceipt? receipt;
  final bool isSending;

  /// The receipt went for every task: the pages go back to the timeline.
  final bool isSent;

  /// The last sending that stopped part way: what went and what didn't.
  final ClientBankTransferOutcome? outcome;
  final ClientBankTransferMessage? message;

  /// Something to pay, somewhere to send it, and the receipt.
  bool get canSend =>
      (transfer?.tasks.isNotEmpty ?? false) &&
      transfer?.bankDetails != null &&
      receipt != null &&
      !isSending;

  ClientBankTransferState copyWith({
    ClientBankTransferStatus? status,
    ClientPaymentSelection? Function()? selection,
    ClientBankTransfer? Function()? transfer,
    Failure? Function()? failure,
    ClientReceipt? Function()? receipt,
    bool? isSending,
    bool? isSent,
    ClientBankTransferOutcome? Function()? outcome,
    ClientBankTransferMessage? Function()? message,
  }) {
    return ClientBankTransferState(
      status: status ?? this.status,
      selection: selection == null ? this.selection : selection(),
      transfer: transfer == null ? this.transfer : transfer(),
      failure: failure == null ? this.failure : failure(),
      receipt: receipt == null ? this.receipt : receipt(),
      isSending: isSending ?? this.isSending,
      isSent: isSent ?? this.isSent,
      outcome: outcome == null ? this.outcome : outcome(),
      message: message == null ? this.message : message(),
    );
  }
}
