import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';

part 'contractor_task_update_step_state.dart';

/// Holds the UI state for `/contractor/tasks/:projectId/updates/new` (GRA-41):
/// the selected task and step progression.
class ContractorTaskUpdateStepCubit
    extends Cubit<ContractorTaskUpdateStepState> {
  ContractorTaskUpdateStepCubit({String? initialTaskId})
    : super(ContractorTaskUpdateStepState(selectedTaskId: initialTaskId));

  void selectTask(String taskId) {
    if (state.selectedTaskId == taskId) return;
    emit(state.copyWith(selectedTaskId: taskId));
  }

  /// Ensures a valid task from [tasks] is selected when the list loads.
  void syncTasks(List<ContractorProjectTask> tasks) {
    if (tasks.isEmpty) {
      emit(
        state.copyWith(
          step: ContractorTaskUpdateStep.chooseTask,
          clearSelectedTaskId: true,
        ),
      );
      return;
    }
    final currentId = state.selectedTaskId;
    final exists =
        currentId != null && tasks.any((task) => task.id == currentId);
    if (!exists) {
      emit(
        state.copyWith(
          step: ContractorTaskUpdateStep.chooseTask,
          selectedTaskId: tasks.first.id,
        ),
      );
    }
  }

  void proceedToStepTwo() {
    if (state.selectedTaskId == null) return;
    emit(state.copyWith(step: ContractorTaskUpdateStep.stateAndEvidence));
  }

  /// Returns to Step 1 while keeping the selected task.
  void backToStepOne() {
    if (state.step == ContractorTaskUpdateStep.chooseTask) return;
    emit(state.copyWith(step: ContractorTaskUpdateStep.chooseTask));
  }
}
