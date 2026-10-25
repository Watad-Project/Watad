import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';

/// What the bank transfer screen shows (GRA-52): the selected tasks read
/// again, the ones that can still be paid and the ones that no longer can,
/// what they add up to, and where to send the money.
class ClientBankTransfer {
  const ClientBankTransfer({
    required this.tasks,
    required this.skippedTasks,
    required this.total,
    this.bankDetails,
  });

  /// The selected tasks the transfer pays, in timeline order.
  final List<ClientPaymentTask> tasks;

  /// Selected tasks that no longer need paying: paid, or a receipt went
  /// for them meanwhile.
  final List<ClientPaymentTask> skippedTasks;

  /// What [tasks] add up to.
  final Money total;

  /// The contractor's account; null until they add it.
  final ClientBankDetails? bankDetails;
}
