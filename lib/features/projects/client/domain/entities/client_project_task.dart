import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';

/// A task of one of the client's projects: a `v_project_tasks` row with
/// `my_role = 'owner'`. The contractor proposes it, the client accepts it,
/// and later approves the contractor's update that says it's done.
class ClientProjectTask {
  const ClientProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.amount,
    this.paymentStatus,
    this.startDate,
    this.finishDate,
    this.lastUpdateId,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;

  /// What the task costs; null for a task without an amount.
  final Money? amount;

  /// The payment stage created when the client approved a priced task.
  final PaymentStatus? paymentStatus;

  /// Riyadh calendar days, without a time. The finish date is set once the
  /// task is done, and never without a start date.
  final DateTime? startDate;
  final DateTime? finishDate;

  /// The contractor's latest update on this task, if any.
  final String? lastUpdateId;
}
