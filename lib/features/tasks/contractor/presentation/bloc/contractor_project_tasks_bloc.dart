import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';

part 'contractor_project_tasks_event.dart';
part 'contractor_project_tasks_state.dart';

/// Manages the contractor's project schedule screen (GRA-37): loads the
/// contract project and its tasks in timeline order.
class ContractorProjectTasksBloc
    extends Bloc<ContractorProjectTasksEvent, ContractorProjectTasksState> {
  ContractorProjectTasksBloc(this._getProject, this._getTasks)
    : super(const ContractorProjectTasksState()) {
    on<ContractorProjectTasksFetched>(_onFetched);
  }

  final ContractorGetTaskProjectUseCase _getProject;
  final ContractorGetProjectTasksUseCase _getTasks;

  Future<void> _onFetched(
    ContractorProjectTasksFetched event,
    Emitter<ContractorProjectTasksState> emit,
  ) async {
    emit(state.copyWith(status: ContractorProjectTasksStatus.loading));
    final (projectResult, tasksResult) = await (
      _getProject(event.projectId),
      _getTasks(event.projectId),
    ).wait;

    switch ((projectResult, tasksResult)) {
      case (Success(data: final project), Success(data: final tasks)):
        emit(
          state.copyWith(
            status: ContractorProjectTasksStatus.success,
            project: project,
            tasks: tasks,
            failure: () => null,
          ),
        );
      case (Failed(:final failure), _) || (_, Failed(:final failure)):
        emit(
          state.copyWith(
            status: ContractorProjectTasksStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
