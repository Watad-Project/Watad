import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';

part 'client_projects_event.dart';
part 'client_projects_state.dart';

class ClientProjectsBloc
    extends Bloc<ClientProjectsEvent, ClientProjectsState> {
  ClientProjectsBloc(this._getMyProjects)
    : super(const ClientProjectsInitial()) {
    on<ClientProjectsFetched>(_onFetched);
  }

  final ClientGetMyProjectsUseCase _getMyProjects;

  Future<void> _onFetched(
    ClientProjectsFetched event,
    Emitter<ClientProjectsState> emit,
  ) async {
    emit(const ClientProjectsLoadInProgress());
    final result = await _getMyProjects(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(ClientProjectsLoadSuccess(data));
      case Failed(:final failure):
        emit(ClientProjectsLoadFailure(failure));
    }
  }
}
