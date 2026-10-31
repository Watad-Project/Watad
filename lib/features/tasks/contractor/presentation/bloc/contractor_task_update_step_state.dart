part of 'contractor_task_update_step_cubit.dart';

enum ContractorTaskUpdateStep { chooseTask, stateAndEvidence }

final class ContractorTaskUpdateStepState {
  const ContractorTaskUpdateStepState({
    this.step = ContractorTaskUpdateStep.chooseTask,
    this.selectedTaskId,
  });

  final ContractorTaskUpdateStep step;
  final String? selectedTaskId;

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
  }) {
    return ContractorTaskUpdateStepState(
      step: step ?? this.step,
      selectedTaskId: clearSelectedTaskId
          ? null
          : (selectedTaskId ?? this.selectedTaskId),
    );
  }
}
