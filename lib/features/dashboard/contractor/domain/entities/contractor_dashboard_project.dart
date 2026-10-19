import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// An in-progress project for the contractor dashboard.
class ContractorDashboardProject {
  const ContractorDashboardProject({
    required this.id,
    required this.title,
    String? ownerName,
    String? clientName,
    required this.status,
    this.approvedTasksCount = 0,
    this.totalTasksCount = 0,
    required this.createdAt,
    this.budget,
    this.city,
  }) : ownerName = ownerName ?? clientName ?? '';

  final String id;
  final String title;
  final String ownerName;
  final ProjectStatus status;
  final int approvedTasksCount;
  final int totalTasksCount;
  final DateTime createdAt;
  final Money? budget;
  final String? city;

  String get clientName => ownerName;

  double get progress {
    if (totalTasksCount <= 0 || approvedTasksCount <= 0) return 0.0;
    final val = approvedTasksCount / totalTasksCount;
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 1.0);
  }

  ContractorDashboardProject copyWith({
    String? id,
    String? title,
    String? ownerName,
    ProjectStatus? status,
    int? approvedTasksCount,
    int? totalTasksCount,
    DateTime? createdAt,
    Money? budget,
    String? city,
  }) {
    return ContractorDashboardProject(
      id: id ?? this.id,
      title: title ?? this.title,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      approvedTasksCount: approvedTasksCount ?? this.approvedTasksCount,
      totalTasksCount: totalTasksCount ?? this.totalTasksCount,
      createdAt: createdAt ?? this.createdAt,
      budget: budget ?? this.budget,
      city: city ?? this.city,
    );
  }
}
