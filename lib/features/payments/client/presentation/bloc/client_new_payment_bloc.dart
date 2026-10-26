import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_task_payability.dart';
import 'package:watad/features/payments/client/domain/usecases/client_calculate_payment_total_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_payment_tasks_use_case.dart';

part 'client_new_payment_event.dart';
part 'client_new_payment_state.dart';

/// «الدفع للمقاول», choosing the tasks (GRA-50): the project's tasks, the
/// ones the client selects, and their total.
class ClientNewPaymentBloc
    extends Bloc<ClientNewPaymentEvent, ClientNewPaymentState> {
  ClientNewPaymentBloc(this._getTasks, this._calculateTotal)
    : super(const ClientNewPaymentState()) {
    on<ClientNewPaymentFetched>(_onFetched);
    on<ClientNewPaymentTaskToggled>(_onToggled);
  }

  final ClientGetPaymentTasksUseCase _getTasks;
  final ClientCalculatePaymentTotalUseCase _calculateTotal;

  Future<void> _onFetched(
    ClientNewPaymentFetched event,
    Emitter<ClientNewPaymentState> emit,
  ) async {
    emit(state.copyWith(status: ClientNewPaymentStatus.loading));
    final result = await _getTasks(event.projectId);
    switch (result) {
      case Success(:final data):
        // A selected task that can't be paid anymore drops out.
        final payable = {
          for (final task in data)
            if (task.payability == ClientTaskPayability.payable) task.id,
        };
        await _select(data, state.selectedIds.intersection(payable), emit);
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientNewPaymentStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onToggled(
    ClientNewPaymentTaskToggled event,
    Emitter<ClientNewPaymentState> emit,
  ) async {
    final selectedIds = {...state.selectedIds};
    if (!selectedIds.remove(event.taskId)) selectedIds.add(event.taskId);
    await _select(state.tasks, selectedIds, emit);
  }

  Future<void> _select(
    List<ClientPaymentTask> tasks,
    Set<String> selectedIds,
    Emitter<ClientNewPaymentState> emit,
  ) async {
    final total = await _calculateTotal([
      for (final task in tasks)
        if (selectedIds.contains(task.id)) task,
    ]);
    switch (total) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ClientNewPaymentStatus.success,
            tasks: tasks,
            selectedIds: selectedIds,
            total: data,
            failure: () => null,
          ),
        );
      case Failed():
        // A task that can't be paid isn't selected: the selection stays.
        emit(
          state.copyWith(
            status: ClientNewPaymentStatus.success,
            tasks: tasks,
            failure: () => null,
          ),
        );
    }
  }
}
