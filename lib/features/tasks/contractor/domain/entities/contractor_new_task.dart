import 'package:watad/core/utils/money.dart';

/// Input payload for proposing a new task on a contract (GRA-38), inserted into
/// `project_tasks` (`docs/ARCHITECTURE.md` §3a).
class ContractorNewTask {
  const ContractorNewTask({
    required this.projectId,
    required this.title,
    required this.description,
    this.amount,
    this.startDate,
  });

  final String projectId;
  final String title;
  final String description;
  final Money? amount;

  /// Optional Riyadh calendar day (`date` column), stored at UTC midnight.
  final DateTime? startDate;
}
