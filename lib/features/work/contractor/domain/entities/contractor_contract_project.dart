import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// A contract project where the contractor is the assigned taker
/// (`v_my_projects` with `my_role = 'taker'`).
class ContractorContractProject {
  const ContractorContractProject({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.ownerName,
    this.budget,
    this.agreedAmount,
    this.totalPaid = const Money.halalas(0),
    required this.city,
    this.district,
    required this.createdAt,
    this.completedAt,
    this.approvedTasksCount = 0,
    this.totalTasksCount = 0,
    this.hasTaskWaitingForClient = false,
  });

  final String id;
  final String title;
  final String? description;
  final ProjectStatus status;
  final String ownerName;
  final Money? budget;
  final Money? agreedAmount;
  final Money totalPaid;
  final String city;
  final String? district;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int approvedTasksCount;
  final int totalTasksCount;
  final bool hasTaskWaitingForClient;

  /// The agreed contract amount, falling back to the project's initial budget.
  Money? get contractMoney => agreedAmount ?? budget;

  bool get isInProgress => status == ProjectStatus.inProgress;

  bool get isCompleted => status == ProjectStatus.completed;

  /// Progress from `0.0` to `1.0` based on approved non-rejected tasks.
  double get progress {
    if (totalTasksCount > 0) {
      return (approvedTasksCount / totalTasksCount).clamp(0.0, 1.0);
    }
    return isCompleted ? 1.0 : 0.0;
  }

  /// Whole-number percentage (`0` to `100`).
  int get progressPercent => (progress * 100).round();
}
