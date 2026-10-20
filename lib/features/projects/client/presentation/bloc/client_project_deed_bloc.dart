import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_replace_deed_use_case.dart';

part 'client_project_deed_event.dart';
part 'client_project_deed_state.dart';

/// A new ownership deed for a project whose deed was rejected: the project,
/// why it was rejected, the file the client picks, and sending it back to
/// review.
class ClientProjectDeedBloc
    extends Bloc<ClientProjectDeedEvent, ClientProjectDeedState> {
  ClientProjectDeedBloc(this._getProject, this._replaceDeed)
    : super(const ClientProjectDeedState()) {
    on<ClientProjectDeedFetched>(_onFetched);
    on<ClientProjectDeedPicked>(_onPicked);
    on<ClientProjectDeedSubmitted>(_onSubmitted);
  }

  final ClientGetProjectUseCase _getProject;
  final ClientReplaceDeedUseCase _replaceDeed;

  Future<void> _onFetched(
    ClientProjectDeedFetched event,
    Emitter<ClientProjectDeedState> emit,
  ) async {
    emit(state.copyWith(status: ClientProjectDeedStatus.loading));
    final result = await _getProject(event.projectId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ClientProjectDeedStatus.ready,
            project: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientProjectDeedStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  void _onPicked(
    ClientProjectDeedPicked event,
    Emitter<ClientProjectDeedState> emit,
  ) {
    emit(
      state.copyWith(
        filePath: () => event.filePath,
        fileName: () => event.fileName,
      ),
    );
  }

  Future<void> _onSubmitted(
    ClientProjectDeedSubmitted event,
    Emitter<ClientProjectDeedState> emit,
  ) async {
    final project = state.project;
    final filePath = state.filePath;
    if (project == null || filePath == null || state.isSending) return;
    emit(state.copyWith(isSending: true, errorKey: () => null));
    final result = await _replaceDeed(
      ClientReplaceDeedParams(projectId: project.id, filePath: filePath),
    );
    switch (result) {
      case Success():
        emit(state.copyWith(isSending: false, isSent: true));
      case Failed(:final failure):
        emit(
          state.copyWith(isSending: false, errorKey: () => failure.messageKey),
        );
    }
  }
}
