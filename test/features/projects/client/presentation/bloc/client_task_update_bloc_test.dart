import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_task_update_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_task_update_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_update_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  ClientTaskUpdate update(TaskUpdateDecision decision) => ClientTaskUpdate(
    id: 'u-3',
    taskTitle: 'اللياسة الداخلية',
    proposedState: TaskUpdateState.done,
    decision: decision,
    createdAt: DateTime.utc(2026, 10, 24, 6, 40),
    projectStatus: ProjectStatus.inProgress,
    taskAmount: const Money.halalas(1500000),
  );

  late FakeClientProjectsRepository repository;

  ClientTaskUpdateBloc buildBloc() => ClientTaskUpdateBloc(
    ClientGetTaskUpdateUseCase(repository),
    ClientAcceptTaskUpdateUseCase(repository),
  );

  Future<ClientTaskUpdateBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ClientTaskUpdateFetched('u-3'));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientTaskUpdateStatus.success,
    );
    return bloc;
  }

  setUp(() {
    repository = FakeClientProjectsRepository()
      ..taskUpdateResult = Success(update(TaskUpdateDecision.pending))
      ..taskUpdateAfterAccept = Success(update(TaskUpdateDecision.accepted));
  });

  test('loads the update, waiting for the client', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.update?.taskTitle, 'اللياسة الداخلية');
    expect(bloc.state.update?.canDecide, isTrue);
    await bloc.close();
  });

  test('fails when the update cannot load', () async {
    repository.taskUpdateResult = const Failed(NotFoundFailure());
    final bloc = buildBloc()..add(const ClientTaskUpdateFetched('u-3'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientTaskUpdateStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    expect(state.update, isNull);
    await bloc.close();
  });

  test('accepting approves the task and reads it back', () async {
    final bloc = await loadedBloc();

    bloc.add(const ClientTaskUpdateAccepted());
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.acceptedUpdates, ['u-3']);
    expect(state.update?.decision, TaskUpdateDecision.accepted);
    expect(state.update?.canDecide, isFalse);
    expect(state.isAccepting, isFalse);
    expect(state.message?.key, 'projects.client.update_accepted');
    expect(state.message?.isError, isFalse);
    await bloc.close();
  });

  test('a refused accept shows the server\'s reason', () async {
    final bloc = await loadedBloc();
    repository.acceptTaskUpdateResult = const Failed(ConflictFailure());

    bloc.add(const ClientTaskUpdateAccepted());
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'errors.conflict');
    expect(state.message?.isError, isTrue);
    expect(state.update?.decision, TaskUpdateDecision.pending);
    await bloc.close();
  });
}
