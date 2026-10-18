import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_project.dart';

class ContractorDashboardProjectModel extends ContractorDashboardProject {
  const ContractorDashboardProjectModel({
    required super.id,
    required super.title,
    super.ownerName,
    super.clientName,
    required super.status,
    super.approvedTasksCount = 0,
    super.totalTasksCount = 0,
    required super.createdAt,
    super.budget,
    super.city,
  });

  factory ContractorDashboardProjectModel.fromJson(Map<String, dynamic> json) {
    final budgetNum = json['budget'] as num?;
    return ContractorDashboardProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      ownerName: (json['owner_name'] ?? json['client_name']) as String? ?? '',
      status: ProjectStatus.fromJson(json['status'] as String),
      approvedTasksCount: json['approved_tasks_count'] as int? ?? 0,
      totalTasksCount: json['total_tasks_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      budget: budgetNum != null ? Money.fromJson(budgetNum) : null,
      city: json['city'] as String?,
    );
  }
}
