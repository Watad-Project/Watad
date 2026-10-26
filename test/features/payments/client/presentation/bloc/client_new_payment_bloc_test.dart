import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/usecases/client_calculate_payment_total_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_payment_tasks_use_case.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_new_payment_bloc.dart';

import '../../../../../helpers/fake_client_payments_repository.dart';

void main() {
  ClientPaymentTask task(
    String id, {
    TaskStatus status = TaskStatus.approved,
    int halalas = 1500000,
    PaymentStatus paymentStatus = PaymentStatus.pending,
  }) => ClientPaymentTask(
    id: id,
    title: 'مهمة $id',
    status: status,
    amount: Money.halalas(halalas),
    paymentId: 'pay-$id',
    paymentStatus: paymentStatus,
  );

  late FakeClientPaymentsRepository repository;

  ClientNewPaymentBloc buildBloc() => ClientNewPaymentBloc(
    ClientGetPaymentTasksUseCase(repository),
    const ClientCalculatePaymentTotalUseCase(),
  );

  Future<ClientNewPaymentBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ClientNewPaymentFetched('p-3'));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientNewPaymentStatus.success,
    );
    return bloc;
  }

  Future<ClientNewPaymentState> toggle(
    ClientNewPaymentBloc bloc,
    String taskId,
  ) async {
    final next = bloc.stream.first;
    bloc.add(ClientNewPaymentTaskToggled(taskId));
    return next;
  }

  setUp(() {
    repository = FakeClientPaymentsRepository()
      ..tasksResult = Success([
        task('t-1'),
        task('t-2', halalas: 2400000),
        task('t-3', paymentStatus: PaymentStatus.paid),
        task('t-4', status: TaskStatus.rejected),
      ]);
  });

  test('loads the tasks without the rejected one, nothing ticked', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.tasks.map((t) => t.id), ['t-1', 't-2', 't-3']);
    expect(bloc.state.selectedIds, isEmpty);
    expect(bloc.state.total, const Money.zero());
    expect(bloc.state.hasPayable, isTrue);
    expect(bloc.state.canContinue, isFalse);
    await bloc.close();
  });

  test('ticking adds a task to the total; unticking takes it out', () async {
    final bloc = await loadedBloc();

    expect((await toggle(bloc, 't-1')).total, const Money.halalas(1500000));
    final both = await toggle(bloc, 't-2');
    expect(both.total, const Money.halalas(3900000));
    expect(both.selectedTasks.map((t) => t.id), ['t-1', 't-2']);
    expect(both.canContinue, isTrue);
    expect((await toggle(bloc, 't-1')).total, const Money.halalas(2400000));
    await bloc.close();
  });

  test('a task that can\'t be paid stays unticked', () async {
    final bloc = await loadedBloc();

    final state = await toggle(bloc, 't-3');
    expect(state.selectedIds, isEmpty);
    expect(state.total, const Money.zero());
    await bloc.close();
  });

  test('fails when the tasks cannot load', () async {
    repository.tasksResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ClientNewPaymentFetched('p-3'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientNewPaymentStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a refresh keeps only the ticked tasks still payable', () async {
    final bloc = await loadedBloc();
    await toggle(bloc, 't-1');
    await toggle(bloc, 't-2');
    // Meanwhile a receipt went for t-2.
    repository.tasksResult = Success([
      task('t-1'),
      task('t-2', halalas: 2400000, paymentStatus: PaymentStatus.processing),
    ]);

    bloc.add(const ClientNewPaymentFetched('p-3'));
    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientNewPaymentStatus.success,
    );
    expect(state.selectedIds, {'t-1'});
    expect(state.total, const Money.halalas(1500000));
    await bloc.close();
  });
}
