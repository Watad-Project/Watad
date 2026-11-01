import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_watch_task_update_use_case.dart';

part 'contractor_task_update_status_event.dart';
part 'contractor_task_update_status_state.dart';

/// Loads a contractor's task update by id and keeps it live via Supabase
/// Realtime (GRA-39).
class ContractorTaskUpdateStatusBloc
    extends
        Bloc<ContractorTaskUpdateStatusEvent, ContractorTaskUpdateStatusState> {
  ContractorTaskUpdateStatusBloc(this._getTaskUpdate, this._watchTaskUpdate)
    : super(const ContractorTaskUpdateStatusState()) {
    on<ContractorTaskUpdateStatusStarted>(_onStarted);
    on<ContractorTaskUpdateStatusRefreshed>(_onRefreshed);
    on<_ContractorTaskUpdateStatusChanged>(_onChanged);
  }

  final ContractorGetTaskUpdateUseCase _getTaskUpdate;
  final ContractorWatchTaskUpdateUseCase _watchTaskUpdate;
  StreamSubscription<Result<ContractorTaskUpdate>>? _subscription;

  Future<void> _onStarted(
    ContractorTaskUpdateStatusStarted event,
    Emitter<ContractorTaskUpdateStatusState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;

    emit(
      state.copyWith(
        status: ContractorTaskUpdateStatusStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _getTaskUpdate(event.updateId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatusStatus.success,
            update: data,
            clearFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatusStatus.failure,
            failure: failure,
          ),
        );
        return;
    }

    final watchResult = await _watchTaskUpdate(event.updateId);
    if (watchResult case Success(data: final stream)) {
      _subscription = stream.listen((eventResult) {
        if (eventResult case Success(data: final updated)) {
          if (!isClosed) {
            add(_ContractorTaskUpdateStatusChanged(updated));
          }
        }
      });
    }
  }

  Future<void> _onRefreshed(
    ContractorTaskUpdateStatusRefreshed event,
    Emitter<ContractorTaskUpdateStatusState> emit,
  ) async {
    if (state.update == null) {
      emit(
        state.copyWith(
          status: ContractorTaskUpdateStatusStatus.loading,
          clearFailure: true,
        ),
      );
    }

    final result = await _getTaskUpdate(event.updateId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatusStatus.success,
            update: data,
            clearFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ContractorTaskUpdateStatusStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onChanged(
    _ContractorTaskUpdateStatusChanged event,
    Emitter<ContractorTaskUpdateStatusState> emit,
  ) {
    emit(
      state.copyWith(
        status: ContractorTaskUpdateStatusStatus.success,
        update: event.update,
        clearFailure: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
