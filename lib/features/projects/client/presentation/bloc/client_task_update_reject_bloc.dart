import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update_rejection.dart';
import 'package:watad/features/projects/client/domain/usecases/client_reject_task_update_use_case.dart';

part 'client_task_update_reject_event.dart';
part 'client_task_update_reject_state.dart';

/// Rejecting a contractor's update (GRA-51): sending the reason and the
/// details.
class ClientTaskUpdateRejectBloc
    extends Bloc<ClientTaskUpdateRejectEvent, ClientTaskUpdateRejectState> {
  ClientTaskUpdateRejectBloc(this._reject)
    : super(const ClientTaskUpdateRejectState()) {
    on<ClientTaskUpdateRejectSubmitted>(_onSubmitted);
  }

  final ClientRejectTaskUpdateUseCase _reject;

  Future<void> _onSubmitted(
    ClientTaskUpdateRejectSubmitted event,
    Emitter<ClientTaskUpdateRejectState> emit,
  ) async {
    if (state.isSending || state.isSent) return;
    emit(state.copyWith(isSending: true, errorKey: () => null));
    final result = await _reject(
      ClientTaskUpdateRejection(
        updateId: event.updateId,
        reason: event.reason,
        details: event.details,
      ),
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
