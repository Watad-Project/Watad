import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// An in-progress project for the contractor dashboard.
class ContractorDashboardProject {
  const ContractorDashboardProject({
    required this.id,
    required this.title,
    required this.clientName,
    required this.status,
    required this.approvedTasksCount,
    required this.totalTasksCount,
    required this.createdAt,
    this.budget,
    this.city,
  });

  final String id;
  final String title;
  final String clientName;
  final ProjectStatus status;
  final int approvedTasksCount;
  final int totalTasksCount;
  final DateTime createdAt;
  final Money? budget;
  final String? city;

  double get progress => totalTasksCount > 0
      ? (approvedTasksCount / totalTasksCount).clamp(0.0, 1.0)
      : 0.0;
}
