import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_payment_tasks_use_case.dart';

import '../../../../../helpers/fake_client_payments_repository.dart';

void main() {
  ClientPaymentTask task(String id, TaskStatus status) =>
      ClientPaymentTask(id: id, title: 'مهمة $id', status: status);

  late FakeClientPaymentsRepository repository;

  setUp(() => repository = FakeClientPaymentsRepository());

  test('leaves out the rejected tasks, in timeline order', () async {
    repository.tasksResult = Success([
      task('t-1', TaskStatus.approved),
      task('t-2', TaskStatus.rejected),
      task('t-3', TaskStatus.accepted),
    ]);

    final result = await ClientGetPaymentTasksUseCase(repository)('p-3');

    expect((result as Success<List<ClientPaymentTask>>).data.map((t) => t.id), [
      't-1',
      't-3',
    ]);
  });

  test('passes a failure on', () async {
    repository.tasksResult = const Failed(NetworkFailure());

    final result = await ClientGetPaymentTasksUseCase(repository)('p-3');

    expect(
      (result as Failed<List<ClientPaymentTask>>).failure,
      isA<NetworkFailure>(),
    );
  });
}
