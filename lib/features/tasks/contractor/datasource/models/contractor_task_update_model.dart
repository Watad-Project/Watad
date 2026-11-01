import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';

class ContractorTaskUpdateModel extends ContractorTaskUpdate {
  const ContractorTaskUpdateModel({
    required super.id,
    required super.taskId,
    required super.taskTitle,
    required super.projectId,
    required super.projectTitle,
    required super.proposedState,
    required super.decision,
    required super.createdAt,
    super.projectDistrict,
    super.projectStatus,
    super.taskAmount,
    super.paymentAmount,
    super.note,
    super.rejectionReason,
    super.rejectionDetails,
    super.rejectionPhotoUrls,
    super.decidedAt,
  });

  /// Maps a row from `v_project_task_updates` (`my_role = 'taker'`, GRA-39),
  /// plus optional `project_district` and `project_status` from `v_my_projects`
  /// and signed `rejection_photo_urls` from `task-evidence`.
  factory ContractorTaskUpdateModel.fromJson(Map<String, dynamic> json) {
    final taskAmount = json['task_amount'] as num?;
    final paymentAmount = json['payment_amount'] as num?;
    final decidedAt = json['decided_at'] as String?;
    final projectStatus = json['project_status'] as String?;
    return ContractorTaskUpdateModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      projectId: json['project_id'] as String,
      projectTitle: json['project_title'] as String,
      projectDistrict: json['project_district'] as String?,
      projectStatus: projectStatus == null
          ? ProjectStatus.inProgress
          : ProjectStatus.fromJson(projectStatus),
      proposedState: TaskUpdateState.fromJson(json['proposed_state'] as String),
      decision: TaskUpdateDecision.fromJson(json['decision'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      decidedAt: decidedAt == null ? null : DateTime.parse(decidedAt),
      taskAmount: taskAmount == null ? null : Money.fromJson(taskAmount),
      paymentAmount: paymentAmount == null
          ? null
          : Money.fromJson(paymentAmount),
      note: json['note'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      rejectionDetails: json['rejection_details'] as String?,
      rejectionPhotoUrls: [
        for (final url
            in json['rejection_photo_urls'] as List<dynamic>? ?? const [])
          url as String,
      ],
    );
  }
}
