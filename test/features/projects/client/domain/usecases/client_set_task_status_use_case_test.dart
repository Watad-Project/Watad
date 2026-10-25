import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_status_params.dart';
import 'package:watad/features/projects/client/domain/usecases/client_set_task_status_use_case.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  late FakeClientProjectsRepository repository;

  setUp(() => repository = FakeClientProjectsRepository());

  test('sends the client\'s answer to a proposed task', () async {
    final result = await ClientSetTaskStatusUseCase(repository)(
      const ClientTaskStatusParams(taskId: 't-5', status: TaskStatus.accepted),
    );

    expect(result, isA<Success<void>>());
    expect(repository.taskStatuses, [('t-5', TaskStatus.accepted)]);
  });

  test('refuses any other status without asking the server', () async {
    for (final status in [
      TaskStatus.proposed,
      TaskStatus.done,
      TaskStatus.approved,
    ]) {
      final result = await ClientSetTaskStatusUseCase(repository)(
        ClientTaskStatusParams(taskId: 't-5', status: status),
      );

      expect(result, isA<Failed<void>>());
      expect((result as Failed<void>).failure, isA<ValidationFailure>());
    }
    expect(repository.taskStatuses, isEmpty);
  });

  test('passes the server\'s refusal on', () async {
    repository.setTaskStatusResult = const Failed(ConflictFailure());

    final result = await ClientSetTaskStatusUseCase(repository)(
      const ClientTaskStatusParams(taskId: 't-5', status: TaskStatus.rejected),
    );

    expect((result as Failed<void>).failure, isA<ConflictFailure>());
  });
}
