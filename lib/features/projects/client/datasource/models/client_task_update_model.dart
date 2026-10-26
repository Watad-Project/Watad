import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';

class ClientTaskUpdateModel extends ClientTaskUpdate {
  const ClientTaskUpdateModel({
    required super.id,
    required super.taskTitle,
    required super.proposedState,
    required super.decision,
    required super.createdAt,
    required super.projectStatus,
    super.taskAmount,
    super.note,
    super.photoUrls,
    super.rejectionReason,
    super.rejectionDetails,
    super.contractorName,
    super.contractorAvatarUrl,
  });

  /// Maps the `v_project_task_updates` columns selected in
  /// ClientProjectsRemoteDataSourceImpl, plus what it adds: `photo_urls`
  /// (signed links to the evidence photos), and `project_status`,
  /// `contractor_name` and `contractor_avatar_url` from `v_my_projects`.
  factory ClientTaskUpdateModel.fromJson(Map<String, dynamic> json) {
    final taskAmount = json['task_amount'] as num?;
    return ClientTaskUpdateModel(
      id: json['id'] as String,
      taskTitle: json['task_title'] as String,
      taskAmount: taskAmount == null ? null : Money.fromJson(taskAmount),
      proposedState: TaskUpdateState.fromJson(json['proposed_state'] as String),
      note: json['note'] as String?,
      photoUrls: [
        for (final url in json['photo_urls'] as List<dynamic>? ?? const [])
          url as String,
      ],
      decision: TaskUpdateDecision.fromJson(json['decision'] as String),
      rejectionReason: json['rejection_reason'] as String?,
      rejectionDetails: json['rejection_details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      projectStatus: ProjectStatus.fromJson(json['project_status'] as String),
      contractorName: json['contractor_name'] as String?,
      contractorAvatarUrl: json['contractor_avatar_url'] as String?,
    );
  }
}
