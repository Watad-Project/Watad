import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';

class ContractorTaskProjectModel extends ContractorTaskProject {
  const ContractorTaskProjectModel({
    required super.id,
    required super.title,
    required super.status,
    required super.ownerName,
    required super.totalPaid,
    required super.totalScheduled,
    required super.createdAt,
    super.city,
    super.district,
    super.agreedAmount,
    super.budget,
    super.photoUrl,
    super.completedAt,
  });

  /// Maps a row from `v_my_projects` (`my_role = 'taker'`) plus `photo_url`
  /// resolved from the first entry in `photo_paths`.
  factory ContractorTaskProjectModel.fromJson(Map<String, dynamic> json) {
    final agreedAmount = json['agreed_amount'] as num?;
    final budget = json['budget'] as num?;
    final totalPaid = json['total_paid'] as num?;
    final totalScheduled = json['total_scheduled'] as num?;
    final completedAt = json['completed_at'] as String?;

    return ContractorTaskProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: ProjectStatus.fromJson(json['status'] as String),
      ownerName: json['owner_name'] as String? ?? '',
      city: json['city'] as String?,
      district: json['district'] as String?,
      agreedAmount: agreedAmount == null ? null : Money.fromJson(agreedAmount),
      budget: budget == null ? null : Money.fromJson(budget),
      totalPaid: totalPaid == null
          ? const Money.zero()
          : Money.fromJson(totalPaid),
      totalScheduled: totalScheduled == null
          ? const Money.zero()
          : Money.fromJson(totalScheduled),
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
    );
  }
}
