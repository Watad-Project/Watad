import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_submit_task_update_use_case.dart';

part 'contractor_task_update_event.dart';
part 'contractor_task_update_state.dart';

/// Loads the contract and its open tasks (`canSendUpdate == true`) for
/// `/contractor/tasks/:projectId/updates/new` (GRA-41) and submits the
/// contractor's progress update (GRA-42).
class ContractorTaskUpdateBloc
    extends Bloc<ContractorTaskUpdateEvent, ContractorTaskUpdateState> {
  ContractorTaskUpdateBloc(
    this._getProject,
    this._getProjectTasks,
    this._submitTaskUpdate,
  ) : super(const ContractorTaskUpdateState()) {
    on<ContractorTaskUpdateFetched>(_onFetched);
    on<ContractorTaskUpdateSubmitted>(_onSubmitted);
  }

  final ContractorGetTaskProjectUseCase _getProject;
  final ContractorGetProjectTasksUseCase _getProjectTasks;
  final ContractorSubmitTaskUpdateUseCase _submitTaskUpdate;

  Future<void> _onFetched(
    ContractorTaskUpdateFetched event,
    Emitter<ContractorTaskUpdateState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ContractorTaskUpdateStatus.loading,
        clearFailure: true,
      ),
    );

    // One after the other, so a failure reaches the screen as it is.
    final ContractorTaskProject project;
    switch (await _getProject(event.projectId)) {
      case Success(:final data):
        project = data;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatus.failure,
            failure: failure,
          ),
        );
        return;
    }

    switch (await _getProjectTasks(event.projectId)) {
      case Success(data: final allTasks):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatus.success,
            project: project,
            tasks: [
              for (final task in allTasks)
                if (task.canSendUpdate) task,
            ],
            clearFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onSubmitted(
    ContractorTaskUpdateSubmitted event,
    Emitter<ContractorTaskUpdateState> emit,
  ) async {
    if (state.isSubmitting) return;
    emit(
      state.copyWith(
        isSubmitting: true,
        clearSubmissionFailure: true,
        clearSubmittedUpdateId: true,
      ),
    );

    final result = await _submitTaskUpdate(event.params);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            isSubmitting: false,
            submittedUpdateId: data,
            clearSubmissionFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(isSubmitting: false, submissionFailure: failure));
    }
  }
}
