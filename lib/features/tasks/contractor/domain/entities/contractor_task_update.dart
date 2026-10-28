import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/utils/money.dart';

/// A task update sent by the contractor (`v_project_task_updates` with
/// `my_role = 'taker'`, GRA-39): what state was proposed, when it was sent,
/// the client's decision and rejection reason, and the payment created when
/// accepted.
class ContractorTaskUpdate {
  const ContractorTaskUpdate({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.projectId,
    required this.projectTitle,
    required this.proposedState,
    required this.decision,
    required this.createdAt,
    this.projectDistrict,
    this.projectStatus = ProjectStatus.inProgress,
    this.taskAmount,
    this.paymentAmount,
    this.note,
    this.rejectionReason,
    this.rejectionDetails,
    this.rejectionPhotoUrls = const [],
    this.decidedAt,
  });

  final String id;
  final String taskId;
  final String taskTitle;
  final String projectId;
  final String projectTitle;
  final String? projectDistrict;
  final ProjectStatus projectStatus;
  final TaskUpdateState proposedState;
  final TaskUpdateDecision decision;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final Money? taskAmount;
  final Money? paymentAmount;
  final String? note;
  final String? rejectionReason;
  final String? rejectionDetails;
  final List<String> rejectionPhotoUrls;

  /// The payment amount created when a priced «منجزة» update is accepted.
  Money? get createdPaymentAmount => paymentAmount ?? taskAmount;

  /// Whether the contractor can send a new update after this one was rejected.
  bool get canSendNewUpdate =>
      decision == TaskUpdateDecision.rejected &&
      projectStatus == ProjectStatus.inProgress;

  /// «فيلا سكنية — حي الياسمين» when [projectDistrict] is present and not
  /// already part of [projectTitle].
  String get displayProjectTitle {
    final trimmedDistrict = projectDistrict?.trim();
    if (trimmedDistrict == null ||
        trimmedDistrict.isEmpty ||
        projectTitle.contains(trimmedDistrict)) {
      return projectTitle;
    }
    return '$projectTitle — $trimmedDistrict';
  }
}
