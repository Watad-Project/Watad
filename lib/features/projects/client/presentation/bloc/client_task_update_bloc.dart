import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_task_update_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_task_update_use_case.dart';

part 'client_task_update_event.dart';
part 'client_task_update_state.dart';

/// One update the contractor sent (GRA-49): what it says, and accepting it.
/// Rejecting it has its own screen.
class ClientTaskUpdateBloc
    extends Bloc<ClientTaskUpdateEvent, ClientTaskUpdateState> {
  ClientTaskUpdateBloc(this._getUpdate, this._accept)
    : super(const ClientTaskUpdateState()) {
    on<ClientTaskUpdateFetched>(_onFetched);
    on<ClientTaskUpdateAccepted>(_onAccepted);
  }

  final ClientGetTaskUpdateUseCase _getUpdate;
  final ClientAcceptTaskUpdateUseCase _accept;

  Future<void> _onFetched(
    ClientTaskUpdateFetched event,
    Emitter<ClientTaskUpdateState> emit,
  ) async {
    emit(state.copyWith(status: ClientTaskUpdateStatus.loading));
    await _load(event.updateId, emit);
  }

  Future<void> _onAccepted(
    ClientTaskUpdateAccepted event,
    Emitter<ClientTaskUpdateState> emit,
  ) async {
    final update = state.update;
    if (update == null || state.isAccepting) return;
    emit(state.copyWith(isAccepting: true, message: () => null));
    final result = await _accept(update.id);
    // Read it again either way: the server decides what changed.
    await _load(update.id, emit);
    emit(
      state.copyWith(
        isAccepting: false,
        message: () => switch (result) {
          Success() => const ClientTaskUpdateMessage(
            'projects.client.update_accepted',
            isError: false,
          ),
          Failed(:final failure) => ClientTaskUpdateMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }

  Future<void> _load(
    String updateId,
    Emitter<ClientTaskUpdateState> emit,
  ) async {
    final result = await _getUpdate(updateId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ClientTaskUpdateStatus.success,
            update: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientTaskUpdateStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
