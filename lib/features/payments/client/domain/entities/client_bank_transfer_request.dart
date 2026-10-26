import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';

/// «إرسال الإيصال للمقاول» (GRA-52): the receipt, for the selected tasks.
class ClientBankTransferRequest {
  const ClientBankTransferRequest({
    required this.selection,
    required this.receipt,
  });

  final ClientPaymentSelection selection;
  final ClientReceipt receipt;
}
