import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';

/// Parameters for submitting a contractor task progress update (GRA-42).
class ContractorSubmitTaskUpdateParams {
  const ContractorSubmitTaskUpdateParams({
    required this.taskId,
    required this.proposedState,
    this.photos = const [],
    this.note,
    this.taskStartDate,
    this.now,
  });

  static const int maxPhotos = 3;
  static const int maxNoteLength = 5000;

  final String taskId;
  final TaskUpdateState proposedState;
  final List<ContractorTaskEvidencePhoto> photos;
  final String? note;

  /// Optional Riyadh calendar `start_date` of the task, checked before
  /// declaring the task `done`.
  final DateTime? taskStartDate;

  /// Optional reference timestamp for deterministic date checks in tests.
  final DateTime? now;
}
