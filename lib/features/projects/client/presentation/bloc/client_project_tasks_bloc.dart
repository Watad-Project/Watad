import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_tasks_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';

part 'client_project_tasks_event.dart';
part 'client_project_tasks_state.dart';

/// The tasks timeline of one project (GRA-47): the project and its tasks.
class ClientProjectTasksBloc
    extends Bloc<ClientProjectTasksEvent, ClientProjectTasksState> {
  ClientProjectTasksBloc(this._getProject, this._getTasks)
    : super(const ClientProjectTasksState()) {
    on<ClientProjectTasksFetched>(_onFetched);
  }

  final ClientGetProjectUseCase _getProject;
  final ClientGetProjectTasksUseCase _getTasks;

  Future<void> _onFetched(
    ClientProjectTasksFetched event,
    Emitter<ClientProjectTasksState> emit,
  ) async {
    emit(state.copyWith(status: ClientProjectTasksStatus.loading));
    final (project, tasks) = await (
      _getProject(event.projectId),
      _getTasks(event.projectId),
    ).wait;
    switch ((project, tasks)) {
      case (Success(data: final p), Success(data: final t)):
        emit(
          state.copyWith(
            status: ClientProjectTasksStatus.success,
            project: p,
            tasks: t,
            failure: () => null,
          ),
        );
      case (Failed(:final failure), _) || (_, Failed(:final failure)):
        emit(
          state.copyWith(
            status: ClientProjectTasksStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
