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
  });

  /// Maps the `v_my_projects` columns selected in
  /// ClientProjectsRemoteDataSourceImpl.
  factory ClientProjectModel.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as num?;
    return ClientProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: ProjectStatus.fromJson(json['status'] as String),
      city: json['city'] as String,
      district: json['district'] as String?,
      budget: budget == null ? null : Money.fromJson(budget),
      pendingOfferCount: json['pending_offer_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
