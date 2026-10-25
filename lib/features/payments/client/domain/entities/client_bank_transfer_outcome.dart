import 'package:watad/core/error/failure.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';

/// What sending a receipt did (GRA-52). Each task's payment stage takes its
/// own transfer, one after the other, and sending stops at the first that
/// fails: some tasks may be sent and some not.
class ClientBankTransferOutcome {
  const ClientBankTransferOutcome({
    required this.sent,
    required this.notSent,
    this.failure,
  });

  /// Sent this time: their stages wait for the contractor to confirm.
  final List<ClientPaymentTask> sent;

  /// Still to send, from the one that failed on.
  final List<ClientPaymentTask> notSent;

  /// Why the first of [notSent] failed.
  final Failure? failure;

  bool get isComplete => notSent.isEmpty;
}
