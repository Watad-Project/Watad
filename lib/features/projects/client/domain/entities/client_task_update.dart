import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/utils/money.dart';

/// An update the contractor sent on a task of one of the client's projects
/// (GRA-49): a `v_project_task_updates` row with `my_role = 'owner'`, with
/// the contractor and the project's status from `v_my_projects`.
class ClientTaskUpdate {
  const ClientTaskUpdate({
    required this.id,
    required this.taskTitle,
    required this.proposedState,
    required this.decision,
    required this.createdAt,
    required this.projectStatus,
    this.taskAmount,
    this.note,
    this.photoUrls = const [],
    this.rejectionReason,
    this.rejectionDetails,
    this.contractorName,
    this.contractorAvatarUrl,
  });

  final String id;
  final String taskTitle;

  /// What approving the task releases; null for a task without an amount.
  final Money? taskAmount;

  /// The state the contractor says the task is in. An «قيد التنفيذ» update
  /// is recorded as accepted at once; a «منجزة» one waits for the client.
  final TaskUpdateState proposedState;
  final String? note;

  /// Short-lived links to the evidence photos, in the private
  /// `task-evidence` bucket.
  final List<String> photoUrls;
  final TaskUpdateDecision decision;

  /// Why the client rejected it, and the details they wrote.
  final String? rejectionReason;
  final String? rejectionDetails;
  final DateTime createdAt;
  final ProjectStatus projectStatus;

  /// The business doing the work, and its photo's URL.
  final String? contractorName;
  final String? contractorAvatarUrl;

  /// The client decides a pending update while the project is in progress
  /// (the server checks it too).
  bool get canDecide =>
      decision == TaskUpdateDecision.pending &&
      projectStatus == ProjectStatus.inProgress;
}
