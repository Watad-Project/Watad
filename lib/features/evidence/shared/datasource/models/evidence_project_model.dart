import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';

class EvidenceProjectModel extends EvidenceProject {
  const EvidenceProjectModel({
    required super.id,
    required super.title,
    required super.status,
    required super.createdAt,
    super.otherParty,
    super.agreedAmount,
  });

  /// Maps the `v_my_projects` columns selected in
  /// EvidenceRemoteDataSourceImpl. The other party is the contractor's
  /// company for the owner, the client's name for the taker.
  factory EvidenceProjectModel.fromJson(Map<String, dynamic> json) {
    final agreed = json['agreed_amount'] as num?;
    final isOwner = json['my_role'] == 'owner';
    return EvidenceProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: ProjectStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      otherParty: isOwner
          ? json['taker_company_name'] as String?
          : json['owner_name'] as String?,
      agreedAmount: agreed == null ? null : Money.fromJson(agreed),
    );
  }
}
