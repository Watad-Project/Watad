import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';

/// A task of one of the client's projects with its payment stage (GRA-50,
/// GRA-52): a `v_project_tasks` row with `my_role = 'owner'`.
class ClientPaymentTask {
  const ClientPaymentTask({
    required this.id,
    required this.title,
    required this.status,
    this.amount,
    this.paymentId,
    this.paymentStatus,
  });

  final String id;
  final String title;
  final TaskStatus status;

  /// What the task costs; null for a task without an amount.
  final Money? amount;

  /// The payment stage created when the client approved the task.
  final String? paymentId;
  final PaymentStatus? paymentStatus;

  /// A task is paid once it's approved and priced, while its stage waits for
  /// the money: `pending`, or `failed` after a failed payment.
  ClientTaskPayability get payability {
    if (status != TaskStatus.approved) return ClientTaskPayability.notApproved;
    if (amount == null) return ClientTaskPayability.noAmount;
    return switch (paymentStatus) {
      PaymentStatus.pending || PaymentStatus.failed when paymentId != null =>
        ClientTaskPayability.payable,
      PaymentStatus.processing => ClientTaskPayability.awaitingConfirmation,
      PaymentStatus.paid => ClientTaskPayability.paid,
      _ => ClientTaskPayability.unavailable,
    };
  }
}
