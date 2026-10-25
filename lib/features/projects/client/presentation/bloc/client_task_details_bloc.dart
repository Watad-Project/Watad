import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_status_params.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_task_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_set_task_status_use_case.dart';

part 'client_task_details_event.dart';
part 'client_task_details_state.dart';

/// A task without updates (GRA-49): what the contractor proposed, and the
/// client's answer while it's proposed.
class ClientTaskDetailsBloc
    extends Bloc<ClientTaskDetailsEvent, ClientTaskDetailsState> {
  ClientTaskDetailsBloc(this._getProject, this._getTask, this._setStatus)
    : super(const ClientTaskDetailsState()) {
    on<ClientTaskDetailsFetched>(_onFetched);
    on<ClientTaskDetailsAnswered>(_onAnswered);
  }

  final ClientGetProjectUseCase _getProject;
  final ClientGetProjectTaskUseCase _getTask;
  final ClientSetTaskStatusUseCase _setStatus;

  Future<void> _onFetched(
    ClientTaskDetailsFetched event,
    Emitter<ClientTaskDetailsState> emit,
  ) async {
    emit(state.copyWith(status: ClientTaskDetailsStatus.loading));
    await _load(event.projectId, event.taskId, emit);
  }

  Future<void> _onAnswered(
    ClientTaskDetailsAnswered event,
    Emitter<ClientTaskDetailsState> emit,
  ) async {
    final project = state.project;
    final task = state.task;
    if (project == null || task == null || state.answering != null) return;
    emit(state.copyWith(answering: () => event.status, errorKey: () => null));
    final result = await _setStatus(
      ClientTaskStatusParams(taskId: task.id, status: event.status),
    );
    switch (result) {
      case Success():
        emit(
          state.copyWith(answering: () => null, answered: () => event.status),
        );
      case Failed(:final failure):
        // The task may have changed meanwhile: show it as it is now.
        await _load(project.id, task.id, emit);
        emit(
          state.copyWith(
            answering: () => null,
            errorKey: () => failure.messageKey,
          ),
        );
    }
  }

  Future<void> _load(
    String projectId,
    String taskId,
    Emitter<ClientTaskDetailsState> emit,
  ) async {
    final (project, task) = await (
      _getProject(projectId),
      _getTask(taskId),
    ).wait;
    switch ((project, task)) {
      case (Success(data: final p), Success(data: final t)):
        emit(
          state.copyWith(
            status: ClientTaskDetailsStatus.success,
            project: p,
            task: t,
            failure: () => null,
          ),
        );
      case (Failed(:final failure), _) || (_, Failed(:final failure)):
        emit(
          state.copyWith(
            status: ClientTaskDetailsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
