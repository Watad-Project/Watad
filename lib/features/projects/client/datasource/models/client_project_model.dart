import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
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
    super.deedStatus,
    super.deedRejectionReason,
    super.photoUrl,
    super.contractorName,
    super.agreedAmount,
    super.taskCount,
    super.approvedTaskCount,
  });

  /// Maps the `v_my_projects` columns selected in
  /// ClientProjectsRemoteDataSourceImpl, plus what it adds: `photo_url` (the
  /// first photo's public URL), `task_count` and `approved_task_count`
  /// (from `v_project_tasks`).
  factory ClientProjectModel.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as num?;
    final agreedAmount = json['agreed_amount'] as num?;
    return ClientProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: ProjectStatus.fromJson(json['status'] as String),
      city: json['city'] as String,
      district: json['district'] as String?,
      budget: budget == null ? null : Money.fromJson(budget),
      pendingOfferCount: json['pending_offer_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      deedStatus: _deedStatus(json['deed_status'] as String?),
      deedRejectionReason: json['deed_rejection_reason'] as String?,
      photoUrl: json['photo_url'] as String?,
      contractorName: json['taker_company_name'] as String?,
      agreedAmount: agreedAmount == null ? null : Money.fromJson(agreedAmount),
      taskCount: json['task_count'] as int? ?? 0,
      approvedTaskCount: json['approved_task_count'] as int? ?? 0,
    );
  }

  /// `projects.deed_status` (ARCHITECTURE.md §4).
  static ClientDeedVerificationStatus _deedStatus(String? value) =>
      switch (value) {
        'under_review' => ClientDeedVerificationStatus.underReview,
        'verified' => ClientDeedVerificationStatus.verified,
        'rejected' => ClientDeedVerificationStatus.rejected,
        _ => ClientDeedVerificationStatus.none,
      };
}
