import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';

import '../../../../../helpers/fake_contractor_tasks_repository.dart';

void main() {
  ContractorTaskProject project(ProjectStatus status) => ContractorTaskProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: status,
    ownerName: 'عبدالله الحربي',
    district: 'حي الياسمين',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(9000000),
    totalScheduled: const Money.halalas(21000000),
    createdAt: DateTime.utc(2026, 1, 5),
  );

  final sampleTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'صب الأساسات والخرسانة',
      status: TaskStatus.approved,
      createdAt: DateTime.utc(2026, 1, 9),
    ),
    ContractorProjectTask(
      id: 't-2',
      projectId: 'p-1',
      title: 'بناء الجدران والهيكل',
      status: TaskStatus.done,
      createdAt: DateTime.utc(2026, 1, 19),
    ),
    ContractorProjectTask(
      id: 't-3',
      projectId: 'p-1',
      title: 'تمديد الكهرباء والسباكة',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 27),
    ),
    ContractorProjectTask(
      id: 't-4',
      projectId: 'p-1',
      title: 'أعمال اللياسة والدهان',
      status: TaskStatus.proposed,
      createdAt: DateTime.utc(2026, 2, 1),
    ),
  ];

  late FakeContractorTasksRepository repository;

  ContractorProjectTasksBloc buildBloc() => ContractorProjectTasksBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
  );

  setUp(() {
    repository = FakeContractorTasksRepository()
      ..projectResult = Success(project(ProjectStatus.inProgress))
      ..tasksResult = Success(sampleTasks);
  });

  test('loads the contract project, its tasks, and summary counts', () async {
    final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ContractorProjectTasksStatus.success,
    );
    expect(state.project?.displayTitle, 'فيلا سكنية — حي الياسمين');
    expect(state.tasks, hasLength(4));
    expect(state.canAddTask, isTrue);
    expect(state.canUpdateTask, isTrue);
    expect(state.doneCount, 1);
    expect(state.proposedCount, 1);
    expect(state.hasSummary, isTrue);
    await bloc.close();
  });

  test(
    'disables update button when no task is accepted without a pending update',
    () async {
      repository.tasksResult = Success([
        sampleTasks[0], // approved
        sampleTasks[1], // done
        ContractorProjectTask(
          id: 't-3',
          projectId: 'p-1',
          title: 'تمديد الكهرباء والسباكة',
          status: TaskStatus.accepted,
          hasPendingUpdate: true,
          createdAt: DateTime.utc(2026, 1, 27),
        ),
      ]);
      final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));

      final state = await bloc.stream.firstWhere(
        (s) => s.status == ContractorProjectTasksStatus.success,
      );
      expect(state.canAddTask, isTrue);
      expect(state.canUpdateTask, isFalse);
      await bloc.close();
    },
  );

  test(
    'marks completed project read-only (hides add/update actions)',
    () async {
      repository.projectResult = Success(project(ProjectStatus.completed));
      final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));

      final state = await bloc.stream.firstWhere(
        (s) => s.status == ContractorProjectTasksStatus.success,
      );
      expect(state.canAddTask, isFalse);
      expect(state.canUpdateTask, isFalse);
      await bloc.close();
    },
  );

  test('emits failure when loading fails and preserves existing data on refresh failure', () async {
    final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ContractorProjectTasksStatus.success,
    );

    repository.tasksResult = const Failed(NetworkFailure());
    bloc.add(const ContractorProjectTasksFetched('p-1'));

    final failedState = await bloc.stream.firstWhere(
      (s) => s.status == ContractorProjectTasksStatus.failure,
    );
    expect(failedState.failure, isA<NetworkFailure>());
    expect(failedState.project?.id, 'p-1');
    expect(failedState.tasks, hasLength(4));
    await bloc.close();
  });
}
