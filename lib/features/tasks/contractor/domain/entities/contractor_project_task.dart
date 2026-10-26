import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/utils/money.dart';

/// A task on the contractor's project schedule (GRA-37), backed by
/// `v_project_tasks` (`my_role = 'taker'`).
class ContractorProjectTask {
  const ContractorProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.amount,
    this.paymentId,
    this.paymentStatus,
    this.startDate,
    this.finishDate,
    this.decidedAt,
    this.lastUpdateId,
    this.lastUpdateProposedState,
    this.lastUpdateDecision,
    this.lastUpdateAt,
    this.hasPendingUpdate = false,
  });

  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;
  final Money? amount;
  final String? paymentId;
  final PaymentStatus? paymentStatus;

  /// Riyadh calendar day (`date` column), stored at UTC midnight so time-zone
  /// conversions never shift the calendar day.
  final DateTime? startDate;

  /// Riyadh calendar day (`date` column), stored at UTC midnight so time-zone
  /// conversions never shift the calendar day.
  final DateTime? finishDate;

  final DateTime? decidedAt;
  final String? lastUpdateId;
  final TaskStatus? lastUpdateProposedState;
  final TaskUpdateDecision? lastUpdateDecision;
  final DateTime? lastUpdateAt;
  final bool hasPendingUpdate;

  /// Whether this task is open for a new progress update from the contractor:
  /// it must be accepted by the client and not currently waiting on a pending
  /// update decision.
  bool get canSendUpdate => status == TaskStatus.accepted && !hasPendingUpdate;

  /// Whether this task has at least one progress update that can be opened.
  bool get hasLatestUpdate => lastUpdateId != null;
}
