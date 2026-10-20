import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';

part 'client_projects_event.dart';
part 'client_projects_state.dart';

/// «مشاريعي»: the projects the client posted.
class ClientProjectsBloc
    extends Bloc<ClientProjectsEvent, ClientProjectsState> {
  ClientProjectsBloc(this._getMyProjects) : super(const ClientProjectsState()) {
    on<ClientProjectsFetched>(_onFetched);
  }

  final ClientGetMyProjectsUseCase _getMyProjects;

  Future<void> _onFetched(
    ClientProjectsFetched event,
    Emitter<ClientProjectsState> emit,
  ) async {
    // The list stays on screen while it reloads.
    if (state.projects.isEmpty) {
      emit(const ClientProjectsState(status: ClientProjectsStatus.loading));
    }
    final result = await _getMyProjects(const NoParams());
    emit(switch (result) {
      Success(:final data) => ClientProjectsState(
        status: ClientProjectsStatus.success,
        projects: data,
      ),
      Failed(:final failure) => ClientProjectsState(
        status: ClientProjectsStatus.failure,
        projects: state.projects,
        failure: failure,
      ),
    });
  }
}
