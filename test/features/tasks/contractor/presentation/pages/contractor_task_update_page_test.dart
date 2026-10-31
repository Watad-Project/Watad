import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_task_update_page.dart';

import '../../../../../helpers/fake_app_session.dart';
import '../../../../../helpers/fake_contractor_tasks_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_component.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  final sampleProject = ContractorTaskProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.inProgress,
    ownerName: 'عبدالله الحربي',
    district: 'حي الياسمين',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(9000000),
    totalScheduled: const Money.halalas(21000000),
    createdAt: DateTime.utc(2026, 1, 5),
  );

  final openTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'بناء الجدران والهيكل',
      status: TaskStatus.accepted,
      amount: const Money.halalas(2400000),
      lastUpdateId: 'upd-prev-1',
      lastUpdateDecision: TaskUpdateDecision.accepted,
      lastUpdateAt: DateTime.utc(2026, 2, 10, 12),
      createdAt: DateTime.utc(2026, 1, 19),
    ),
    ContractorProjectTask(
      id: 't-2',
      projectId: 'p-1',
      title: 'تمديد الكهرباء والسباكة',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 27),
    ),
  ];

  late FakeContractorTasksRepository repository;

  ContractorTaskUpdateBloc buildUpdateBloc() => ContractorTaskUpdateBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
  );

  ContractorProjectTasksBloc buildScheduleBloc() => ContractorProjectTasksBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
  );

  setUp(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeContractorTasksRepository()
      ..projectResult = Success(sampleProject)
      ..tasksResult = Success(openTasks);
    getIt
      ..registerFactory<ContractorProjectTasksBloc>(buildScheduleBloc)
      ..registerFactory<ContractorTaskUpdateBloc>(buildUpdateBloc)
      ..registerFactory<ContractorTaskUpdateStepCubit>(
        () => ContractorTaskUpdateStepCubit(initialTaskId: null),
      );
  });

  tearDown(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
  });

  testWidgets(
    'Step 1 (GRA-41): renders open tasks, selects task, and advances to Step 2',
    (tester) async {
      final bloc = buildUpdateBloc()
        ..add(const ContractorTaskUpdateFetched('p-1'));
      final cubit = ContractorTaskUpdateStepCubit();
      addTearDown(bloc.close);
      addTearDown(cubit.close);

      await pumpLocalizedApp(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: cubit),
          ],
          child: ContractorTaskUpdatePage(
            projectId: 'p-1',
            now: DateTime.utc(2026, 2, 12, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ما المهمة التي تريد تحديثها؟'), findsOneWidget);
      expect(find.text('بناء الجدران والهيكل'), findsOneWidget);
      expect(find.text('تمديد الكهرباء والسباكة'), findsOneWidget);
      expect(find.text('آخر تحديث: قبل يومين'), findsOneWidget);
      expect(find.text('لم يُرسل تحديث بعد'), findsOneWidget);

      await tester.tap(find.byKey(const Key('contractor_task_choice_t-2')));
      await tester.pump();
      expect(cubit.state.selectedTaskId, 't-2');

      await tester.tap(find.byKey(const Key('contractor_task_update_next')));
      await tester.pump();
      expect(cubit.state.step, ContractorTaskUpdateStep.stateAndEvidence);
    },
  );

  testWidgets(
    'navigates from schedule «تحديث مهمة» button to /contractor/tasks/:projectId/updates/new',
    (tester) async {
      await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.contractor),
        initialLocation: '/contractor/tasks/p-1',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('contractor_project_tasks_update')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContractorTaskUpdatePage), findsOneWidget);
      expect(find.text('ما المهمة التي تريد تحديثها؟'), findsOneWidget);
    },
  );

  testWidgets('renders Step 1 without overflow at 200% bold text scale', (
    tester,
  ) async {
    final bloc = buildUpdateBloc()
      ..add(const ContractorTaskUpdateFetched('p-1'));
    final cubit = ContractorTaskUpdateStepCubit();
    addTearDown(bloc.close);
    addTearDown(cubit.close);

    await pumpLocalizedApp(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: cubit),
        ],
        child: ContractorTaskUpdatePage(
          projectId: 'p-1',
          now: DateTime.utc(2026, 2, 12, 12),
        ),
      ),
      textScale: largeTextScale,
      boldText: true,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
