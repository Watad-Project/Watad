import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';

class ContractorContractProjectModel extends ContractorContractProject {
  const ContractorContractProjectModel({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.ownerName,
    super.budget,
    super.agreedAmount,
    super.totalPaid,
    required super.city,
    super.district,
    required super.createdAt,
    super.completedAt,
    super.approvedTasksCount,
    super.totalTasksCount,
    super.hasTaskWaitingForClient,
  });

  factory ContractorContractProjectModel.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'in_progress';
    final status = ProjectStatus.fromJson(statusRaw);

    final createdAtRaw = json['created_at'] as String?;
    final createdAt = createdAtRaw != null
        ? (DateTime.tryParse(createdAtRaw) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final completedAtRaw = json['completed_at'] as String?;
    final completedAt = completedAtRaw != null
        ? DateTime.tryParse(completedAtRaw)
        : null;

    var approvedCount = (json['approved_tasks_count'] as num?)?.toInt() ?? 0;
    var totalCount = (json['total_tasks_count'] as num?)?.toInt() ?? 0;
    var waitingForClient =
        json['has_task_waiting_for_client'] as bool? ?? false;

    if (json['tasks'] case final List<dynamic> taskRows) {
      approvedCount = 0;
      totalCount = 0;
      waitingForClient = false;
      for (final rawTask in taskRows) {
        if (rawTask is! Map) continue;
        final taskMap = Map<String, dynamic>.from(rawTask);
        final taskStatusRaw = taskMap['status'] as String?;
        if (taskStatusRaw == null) continue;
        final taskStatus = TaskStatus.fromJson(taskStatusRaw);
        if (taskStatus == TaskStatus.rejected) continue;
        totalCount++;
        if (taskStatus == TaskStatus.approved) {
          approvedCount++;
        }
        if (taskStatus == TaskStatus.proposed ||
            taskStatus == TaskStatus.done) {
          waitingForClient = true;
        }
      }
    }

    return ContractorContractProjectModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: status,
      ownerName: json['owner_name'] as String? ?? '',
      budget: json['budget'] != null
          ? Money.fromJson(json['budget'] as num)
          : null,
      agreedAmount: json['agreed_amount'] != null
          ? Money.fromJson(json['agreed_amount'] as num)
          : null,
      totalPaid: json['total_paid'] != null
          ? Money.fromJson(json['total_paid'] as num)
          : const Money.halalas(0),
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      createdAt: createdAt,
      completedAt: completedAt,
      approvedTasksCount: approvedCount,
      totalTasksCount: totalCount,
      hasTaskWaitingForClient: waitingForClient,
    );
  }
}
