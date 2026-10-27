part of 'contractor_task_update_step_cubit.dart';

enum ContractorTaskUpdateStep { chooseTask, stateAndEvidence }

final class ContractorTaskUpdateStepState {
  const ContractorTaskUpdateStepState({
    this.step = ContractorTaskUpdateStep.chooseTask,
    this.selectedTaskId,
    this.proposedState = TaskUpdateState.inProgress,
    this.photos = const [],
    this.note = '',
  });

  final ContractorTaskUpdateStep step;
  final String? selectedTaskId;
  final TaskUpdateState proposedState;
  final List<ContractorTaskEvidencePhoto> photos;
  final String note;

  bool get canAddPhoto =>
      photos.length < ContractorSubmitTaskUpdateParams.maxPhotos;

  /// Resolves the currently selected [ContractorProjectTask] from [tasks].
  ContractorProjectTask? selectedTaskFrom(List<ContractorProjectTask> tasks) {
    final id = selectedTaskId;
    if (id == null) return null;
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  ContractorTaskUpdateStepState copyWith({
    ContractorTaskUpdateStep? step,
    String? selectedTaskId,
    bool clearSelectedTaskId = false,
    TaskUpdateState? proposedState,
    List<ContractorTaskEvidencePhoto>? photos,
    String? note,
  }) {
    return ContractorTaskUpdateStepState(
      step: step ?? this.step,
      selectedTaskId: clearSelectedTaskId
          ? null
          : (selectedTaskId ?? this.selectedTaskId),
      proposedState: proposedState ?? this.proposedState,
      photos: photos ?? this.photos,
      note: note ?? this.note,
    );
  }
}
