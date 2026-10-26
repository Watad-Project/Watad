part of 'client_bank_transfer_bloc.dart';

sealed class ClientBankTransferEvent {
  const ClientBankTransferEvent();
}

/// The page opened for the selected tasks, or the client tapped retry.
final class ClientBankTransferFetched extends ClientBankTransferEvent {
  const ClientBankTransferFetched(this.selection);

  final ClientPaymentSelection selection;
}

/// The client picked a receipt: a file or a photo.
final class ClientBankTransferReceiptPicked extends ClientBankTransferEvent {
  const ClientBankTransferReceiptPicked(this.receipt);

  final ClientReceipt receipt;
}

/// «إرسال الإيصال للمقاول», or sending it again for the rest.
final class ClientBankTransferSubmitted extends ClientBankTransferEvent {
  const ClientBankTransferSubmitted();
}
