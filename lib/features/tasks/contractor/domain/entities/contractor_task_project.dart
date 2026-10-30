import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';

/// A contract project as seen on the contractor's project schedule screen
/// (GRA-37), backed by `v_my_projects` (`my_role = 'taker'`).
class ContractorTaskProject {
  const ContractorTaskProject({
    required this.id,
    required this.title,
    required this.status,
    required this.ownerName,
    required this.totalPaid,
    required this.totalScheduled,
    required this.createdAt,
    this.city,
    this.district,
    this.agreedAmount,
    this.budget,
    this.photoUrl,
    this.completedAt,
    this.ownerId,
  });

  final String id;
  final String title;
  final ProjectStatus status;
  final String ownerName;

  /// The client's user id: who «مراسلة العميل» opens a chat with.
  final String? ownerId;
  final String? city;
  final String? district;
  final Money? agreedAmount;
  final Money? budget;
  final Money totalPaid;
  final Money totalScheduled;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// The contract's agreed amount, falling back to the project's budget.
  Money? get contractAmount => agreedAmount ?? budget;

  /// Only `in_progress` contracts can add or update tasks; `completed`
  /// contracts are read-only.
  bool get isInProgress => status == ProjectStatus.inProgress;

  /// «فيلا سكنية — حي الياسمين» when [district] is present and not already
  /// part of [title].
  String get displayTitle {
    final trimmedDistrict = district?.trim();
    if (trimmedDistrict == null ||
        trimmedDistrict.isEmpty ||
        title.contains(trimmedDistrict)) {
      return title;
    }
    return '$title — $trimmedDistrict';
  }

  /// Amount left under [agreedAmount] that can still be assigned to tasks
  /// (GRA-38): `agreed_amount - total_scheduled - sum(proposed/accepted/done`
  /// tasks without a `payment_id`). Returns `null` when [agreedAmount] is not
  /// set.
  Money? remainingBudget(List<ContractorProjectTask> tasks) {
    final cap = agreedAmount;
    if (cap == null) return null;
    var unscheduled = const Money.zero();
    for (final task in tasks) {
      final taskAmount = task.amount;
      if (taskAmount == null || task.paymentId != null) continue;
      switch (task.status) {
        case TaskStatus.proposed || TaskStatus.accepted || TaskStatus.done:
          unscheduled = unscheduled + taskAmount;
        case TaskStatus.approved || TaskStatus.rejected:
          break;
      }
    }
    final remaining = cap - totalScheduled - unscheduled;
    return remaining < const Money.zero() ? const Money.zero() : remaining;
  }
}
