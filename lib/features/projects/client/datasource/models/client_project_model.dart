import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

class ClientProjectModel extends ClientProject {
  const ClientProjectModel({
    required super.id,
    required super.title,
    required super.status,
    required super.city,
    required super.pendingOfferCount,
    required super.createdAt,
    super.district,
    super.budget,
    super.budgetMin,
    super.budgetMax,
    super.projectType,
    super.deedStatus,
    super.rejectionReason,
  });

  /// Maps the columns selected in ClientProjectsRemoteDataSourceImpl.
  factory ClientProjectModel.fromJson(Map<String, dynamic> json) {
    final rawBudget = json['budget'] as num?;
    final rawBudgetMin = json['budget_min'] as num?;
    final rawBudgetMax = json['budget_max'] as num?;
    return ClientProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: ProjectStatus.fromJson(json['status'] as String),
      city: json['city'] as String,
      pendingOfferCount: json['pending_offer_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      district: json['district'] as String?,
      budget: rawBudget == null ? null : Money.fromJson(rawBudget),
      budgetMin: rawBudgetMin == null ? null : Money.fromJson(rawBudgetMin),
      budgetMax: rawBudgetMax == null ? null : Money.fromJson(rawBudgetMax),
      projectType: json['project_type'] as String?,
      deedStatus: json['deed_status'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
