import 'package:watad/core/enums/task_status.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_task.dart';

class ContractorDashboardTaskModel extends ContractorDashboardTask {
  const ContractorDashboardTaskModel({
    required super.id,
    required super.projectId,
    required super.status,
  });

  factory ContractorDashboardTaskModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'proposed';
    final status = TaskStatus.values.firstWhere(
      (e) => e.value == statusStr,
      orElse: () => TaskStatus.proposed,
    );

    return ContractorDashboardTaskModel(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      status: status,
    );
  }
}
