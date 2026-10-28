import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_watch_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_status_bloc.dart';

import '../../../../../helpers/fake_contractor_tasks_repository.dart';

void main() {
  late FakeContractorTasksRepository repository;

  ContractorTaskUpdateStatusBloc buildBloc() => ContractorTaskUpdateStatusBloc(
    ContractorGetTaskUpdateUseCase(repository),
    ContractorWatchTaskUpdateUseCase(repository),
  );

  setUp(() {
    repository = FakeContractorTasksRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  test(
    'loads initial task update and emits live Realtime decision changes',
    () async {
      final bloc = buildBloc()
        ..add(const ContractorTaskUpdateStatusStarted('upd-1'));
      addTearDown(bloc.close);

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContractorTaskUpdateStatusState>().having(
            (s) => s.status,
            'status',
            ContractorTaskUpdateStatusStatus.loading,
          ),
          isA<ContractorTaskUpdateStatusState>()
              .having(
                (s) => s.status,
                'status',
                ContractorTaskUpdateStatusStatus.success,
              )
              .having(
                (s) => s.update?.decision,
                'decision',
                TaskUpdateDecision.pending,
              ),
        ]),
      );

      final acceptedUpdate = ContractorTaskUpdate(
        id: 'upd-1',
        taskId: 't-1',
        taskTitle: 'اللياسة الداخلية',
        projectId: 'p-1',
        projectTitle: 'فيلا سكنية',
        projectDistrict: 'حي الياسمين',
        proposedState: TaskUpdateState.done,
        decision: TaskUpdateDecision.accepted,
        paymentAmount: const Money.halalas(2400000),
        createdAt: DateTime.utc(2026, 10, 28, 6, 40),
      );
      repository.emitLiveUpdate(Success(acceptedUpdate));

      await expectLater(
        bloc.stream,
        emits(
          isA<ContractorTaskUpdateStatusState>().having(
            (s) => s.update?.decision,
            'decision',
            TaskUpdateDecision.accepted,
          ),
        ),
      );
    },
  );

  test(
    'emits failure when task update is not found and recovers on refresh',
    () async {
      repository.taskUpdateResult = const Failed(NotFoundFailure());
      final bloc = buildBloc()
        ..add(const ContractorTaskUpdateStatusStarted('upd-missing'));
      addTearDown(bloc.close);

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContractorTaskUpdateStatusState>().having(
            (s) => s.status,
            'status',
            ContractorTaskUpdateStatusStatus.loading,
          ),
          isA<ContractorTaskUpdateStatusState>()
              .having(
                (s) => s.status,
                'status',
                ContractorTaskUpdateStatusStatus.failure,
              )
              .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
        ]),
      );

      repository.taskUpdateResult = Success(
        ContractorTaskUpdate(
          id: 'upd-missing',
          taskId: 't-1',
          taskTitle: 'اللياسة الداخلية',
          projectId: 'p-1',
          projectTitle: 'فيلا سكنية',
          proposedState: TaskUpdateState.done,
          decision: TaskUpdateDecision.pending,
          createdAt: DateTime.utc(2026, 10, 28, 6, 40),
        ),
      );
      bloc.add(const ContractorTaskUpdateStatusRefreshed('upd-missing'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContractorTaskUpdateStatusState>().having(
            (s) => s.status,
            'status',
            ContractorTaskUpdateStatusStatus.loading,
          ),
          isA<ContractorTaskUpdateStatusState>().having(
            (s) => s.status,
            'status',
            ContractorTaskUpdateStatusStatus.success,
          ),
        ]),
      );
    },
  );
}
