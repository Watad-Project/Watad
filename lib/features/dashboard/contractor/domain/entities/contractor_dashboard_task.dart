import 'package:watad/core/enums/task_status.dart';

/// A task row from `v_project_tasks`.
class ContractorDashboardTask {
  const ContractorDashboardTask({
    required this.id,
    required this.projectId,
    required this.status,
  });

  final String id;
  final String projectId;
  final TaskStatus status;
}
