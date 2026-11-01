import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_create_task_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_add_task_bloc.dart';

import '../../../../../helpers/fake_contractor_tasks_repository.dart';

void main() {
  ContractorTaskProject project({
    ProjectStatus status = ProjectStatus.inProgress,
  }) => ContractorTaskProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: status,
    ownerName: 'عبدالله الحربي',
    district: 'حي الياسمين',
    agreedAmount: Money.fromSar(480000),
    totalPaid: Money.fromSar(90000),
    totalScheduled: Money.fromSar(210000),
    createdAt: DateTime.utc(2026, 1, 5),
  );

  final existingTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'تمديد الكهرباء',
      status: TaskStatus.accepted,
      amount: Money.fromSar(70000),
      createdAt: DateTime.utc(2026, 1, 10),
    ),
  ];

  late FakeContractorTasksRepository repository;

  ContractorAddTaskBloc buildBloc() => ContractorAddTaskBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
    ContractorCreateTaskUseCase(repository),
  );

  setUp(() {
    repository = FakeContractorTasksRepository()
      ..projectResult = Success(project())
      ..tasksResult = Success(existingTasks);
  });

  test('loads project and computes remaining contract budget', () async {
    final bloc = buildBloc()..add(const ContractorAddTaskStarted('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ContractorAddTaskStatus.ready,
    );
    // 480,000 - 210,000 - 70,000 = 200,000 SAR
    expect(state.amountLeft, Money.fromSar(200000));
    await bloc.close();
  });

  test('validates required title, description, and amount exceeding remaining budget', () async {
    final bloc = buildBloc()..add(const ContractorAddTaskStarted('p-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ContractorAddTaskStatus.ready,
    );

    bloc.add(
      const ContractorAddTaskSubmitted(
        projectId: 'p-1',
        title: 'أ',
        description: '   ',
        rawAmount: '250000',
      ),
    );

    final state = await bloc.stream.firstWhere((s) => s.titleErrorKey != null);
    expect(state.titleErrorKey, 'tasks.contractor.add_error_title_length');
    expect(
      state.descriptionErrorKey,
      'tasks.contractor.add_error_description_required',
    );
    expect(
      state.amountErrorKey,
      'tasks.contractor.add_error_amount_exceeds_remaining',
    );
    expect(repository.lastCreatedTask, isNull);
    await bloc.close();
  });

  test(
    'submits valid task with Arabic-Indic digits and optional start date',
    () async {
      final bloc = buildBloc()..add(const ContractorAddTaskStarted('p-1'));
      await bloc.stream.firstWhere(
        (s) => s.status == ContractorAddTaskStatus.ready,
      );

      bloc
        ..add(ContractorAddTaskStartDateChanged(DateTime.utc(2026, 10, 15)))
        ..add(
          const ContractorAddTaskSubmitted(
            projectId: 'p-1',
            title: 'العزل المائي للسطح',
            description: 'طبقتان من العزل البيتوميني مع اختبار غمر ٤٨ ساعة.',
            rawAmount: '٣٨٬٠٠٠',
          ),
        );

      final state = await bloc.stream.firstWhere((s) => s.isSubmitted);
      expect(state.isSubmitted, isTrue);
      expect(repository.lastCreatedTask?.projectId, 'p-1');
      expect(repository.lastCreatedTask?.title, 'العزل المائي للسطح');
      expect(repository.lastCreatedTask?.amount, Money.fromSar(38000));
      expect(repository.lastCreatedTask?.startDate, DateTime.utc(2026, 10, 15));
      await bloc.close();
    },
  );

  test('refuses submission when project is no longer in progress', () async {
    repository.projectResult = Success(
      project(status: ProjectStatus.completed),
    );
    final bloc = buildBloc()..add(const ContractorAddTaskStarted('p-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ContractorAddTaskStatus.ready,
    );

    bloc.add(
      const ContractorAddTaskSubmitted(
        projectId: 'p-1',
        title: 'العزل المائي للسطح',
        description: 'طبقتان من العزل البيتوميني.',
        rawAmount: '',
      ),
    );

    final state = await bloc.stream.firstWhere(
      (s) => s.submissionFailure != null,
    );
    expect(state.submissionFailure, isA<ValidationFailure>());
    expect(repository.lastCreatedTask, isNull);
    await bloc.close();
  });
}
