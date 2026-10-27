import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';

part 'contractor_task_update_step_state.dart';

/// Holds the two-step UI state for `/contractor/tasks/:projectId/updates/new`
/// (GRA-41 & GRA-42): selected task, step progression, proposed state,
/// evidence photos, and note.
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

  /// Returns to Step 1 while keeping the selected task, state, photos, and note.
  void backToStepOne() {
    if (state.step == ContractorTaskUpdateStep.chooseTask) return;
    emit(state.copyWith(step: ContractorTaskUpdateStep.chooseTask));
  }

  void setProposedState(TaskUpdateState proposedState) {
    if (state.proposedState == proposedState) return;
    emit(state.copyWith(proposedState: proposedState));
  }

  void addPhoto(ContractorTaskEvidencePhoto photo) {
    if (!state.canAddPhoto) return;
    emit(state.copyWith(photos: [...state.photos, photo]));
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= state.photos.length) return;
    final updated = [...state.photos]..removeAt(index);
    emit(state.copyWith(photos: updated));
  }

  void setNote(String note) {
    if (state.note == note) return;
    emit(state.copyWith(note: note));
  }
}
