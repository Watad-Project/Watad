import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/contractor_tasks_injection.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_submit_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_watch_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_status_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_task_update_page.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_task_update_status_page.dart';

import '../../../../../helpers/fake_app_session.dart';
import '../../../../../helpers/fake_contractor_tasks_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_component.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  final sentAtLocal = DateTime(2026, 10, 28, 9, 40);

  ContractorTaskUpdate buildUpdate({
    TaskUpdateDecision decision = TaskUpdateDecision.pending,
    TaskUpdateState proposedState = TaskUpdateState.done,
    Money? taskAmount = const Money.halalas(2400000),
    Money? paymentAmount,
    String? rejectionReason,
    String? rejectionDetails,
  }) {
    return ContractorTaskUpdate(
      id: 'upd-1',
      taskId: 't-2',
      taskTitle: 'اللياسة الداخلية',
      projectId: 'p-1',
      projectTitle: 'فيلا سكنية',
      projectDistrict: 'حي الياسمين',
      proposedState: proposedState,
      decision: decision,
      taskAmount: taskAmount,
      paymentAmount: paymentAmount,
      rejectionReason: rejectionReason,
      rejectionDetails: rejectionDetails,
      createdAt: sentAtLocal,
    );
  }

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

  final sampleTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'صب الأساسات والخرسانة',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 10),
    ),
    ContractorProjectTask(
      id: 't-2',
      projectId: 'p-1',
      title: 'اللياسة الداخلية',
      status: TaskStatus.accepted,
      amount: const Money.halalas(2400000),
      lastUpdateId: 'upd-1',
      lastUpdateDecision: TaskUpdateDecision.rejected,
      createdAt: DateTime.utc(2026, 1, 20),
    ),
  ];

  late FakeContractorTasksRepository repository;

  ContractorTaskUpdateStatusBloc buildStatusBloc() =>
      ContractorTaskUpdateStatusBloc(
        ContractorGetTaskUpdateUseCase(repository),
        ContractorWatchTaskUpdateUseCase(repository),
      );

  ContractorProjectTasksBloc buildScheduleBloc() => ContractorProjectTasksBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
  );

  ContractorTaskUpdateBloc buildUpdateBloc() => ContractorTaskUpdateBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
    ContractorSubmitTaskUpdateUseCase(repository),
  );

  setUp(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeContractorTasksRepository()
      ..projectResult = Success(sampleProject)
      ..tasksResult = Success(sampleTasks)
      ..taskUpdateResult = Success(buildUpdate());
    getIt
      ..registerFactory<ContractorProjectTasksBloc>(buildScheduleBloc)
      ..registerFactory<ContractorTaskUpdateBloc>(buildUpdateBloc)
      ..registerFactory<ContractorTaskUpdateStepCubit>(
        () => ContractorTaskUpdateStepCubit(initialTaskId: null),
      )
      ..registerFactory<ContractorTaskUpdateStatusBloc>(buildStatusBloc);
  });

  tearDown(() async {
    await repository.dispose();
    await getIt.reset();
    AppNotificationLinks.clear();
  });

  testWidgets(
    'renders pending card and updates live via Realtime when client accepts or rejects',
    (tester) async {
      final bloc = buildStatusBloc()
        ..add(const ContractorTaskUpdateStatusStarted('upd-1'));
      addTearDown(bloc.close);

      await pumpLocalizedApp(
        tester,
        BlocProvider.value(
          value: bloc,
          child: ContractorTaskUpdateStatusPage(
            projectId: 'p-1',
            updateId: 'upd-1',
            now: sentAtLocal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فيلا سكنية — حي الياسمين'), findsOneWidget);
      expect(find.text('اللياسة الداخلية'), findsOneWidget);
      expect(
        find.text('أُرسل اليوم ٩:٤٠ ص · الحالة المقترحة: منجزة'),
        findsOneWidget,
      );
      final pendingCard = tester.widget<AppStatusCard>(
        find.byKey(const Key('contractor_task_update_status_card_pending')),
      );
      expect(pendingCard.tone, AppTone.attention);
      expect(find.text('بانتظار مراجعة العميل'), findsOneWidget);
      expect(
        find.text('لا يمكن إرسال تحديث آخر لهذه المهمة حتى يقرر العميل.'),
        findsOneWidget,
      );

      // Client rejects via Realtime -> card switches live to red with reason & retry button.
      repository.emitLiveUpdate(
        Success(
          buildUpdate(
            decision: TaskUpdateDecision.rejected,
            rejectionReason: 'الأدلة غير كافية',
            rejectionDetails: 'لا تظهر زوايا السقف، والتشقق عند النافذة الشرقية ما زال ظاهراً.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rejectedCard = tester.widget<AppStatusCard>(
        find.byKey(const Key('contractor_task_update_status_card_rejected')),
      );
      expect(rejectedCard.tone, AppTone.danger);
      expect(find.text('رفض العميل التحديث'), findsOneWidget);
      expect(find.text('الأدلة غير كافية'), findsOneWidget);
      expect(
        find.text(
          'لا تظهر زوايا السقف، والتشقق عند النافذة الشرقية ما زال ظاهراً.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('contractor_task_update_status_retry')),
        findsOneWidget,
      );

      // Client accepts via Realtime -> card switches live to green with payment amount.
      repository.emitLiveUpdate(
        Success(
          buildUpdate(
            decision: TaskUpdateDecision.accepted,
            paymentAmount: const Money.halalas(2400000),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final acceptedCard = tester.widget<AppStatusCard>(
        find.byKey(const Key('contractor_task_update_status_card_accepted')),
      );
      expect(acceptedCard.tone, AppTone.success);
      expect(find.text('قبل العميل التحديث'), findsOneWidget);
      expect(
        find.text('المهمة معتمدة · أُنشئت دفعة ٢٤٬٠٠٠ ر.س'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders accepted card without payment part when task has no amount',
    (tester) async {
      repository.taskUpdateResult = Success(
        buildUpdate(
          decision: TaskUpdateDecision.accepted,
          taskAmount: null,
          paymentAmount: null,
        ),
      );
      final bloc = buildStatusBloc()
        ..add(const ContractorTaskUpdateStatusStarted('upd-1'));
      addTearDown(bloc.close);

      await pumpLocalizedApp(
        tester,
        BlocProvider.value(
          value: bloc,
          child: ContractorTaskUpdateStatusPage(
            projectId: 'p-1',
            updateId: 'upd-1',
            now: sentAtLocal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('قبل العميل التحديث'), findsOneWidget);
      expect(find.text('المهمة معتمدة'), findsOneWidget);
    },
  );

  testWidgets(
    'opens from schedule task tap and «إرسال تحديث جديد» opens GRA-42 with task already chosen',
    (tester) async {
      repository.taskUpdateResult = Success(
        buildUpdate(
          decision: TaskUpdateDecision.rejected,
          rejectionReason: 'الأدلة غير كافية',
          rejectionDetails:
              'لا تظهر زوايا السقف، والتشقق عند النافذة الشرقية ما زال ظاهراً.',
        ),
      );

      await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.contractor),
        initialLocation: '/contractor/tasks/p-1',
      );
      await tester.pumpAndSettle();

      // Tap the task tag on the schedule (GRA-37) -> opens GRA-39 status page.
      await tester.tap(find.byKey(const Key('contractor_task_update_t-2')));
      await tester.pumpAndSettle();

      expect(find.byType(ContractorTaskUpdateStatusPage), findsOneWidget);
      expect(find.text('رفض العميل التحديث'), findsOneWidget);

      // Tap «إرسال تحديث جديد» -> opens GRA-42 Step 2 with task t-2 already chosen.
      await tester.tap(
        find.byKey(const Key('contractor_task_update_status_retry')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContractorTaskUpdatePage), findsOneWidget);
      expect(
        find.byKey(const Key('contractor_task_update_selected_card')),
        findsOneWidget,
      );
      expect(find.text('اللياسة الداخلية'), findsOneWidget);
    },
  );

  testWidgets('shows error/not-found state and retries on tap', (tester) async {
    repository.taskUpdateResult = const Failed(NotFoundFailure());
    final bloc = buildStatusBloc()
      ..add(const ContractorTaskUpdateStatusStarted('upd-missing'));
    addTearDown(bloc.close);

    await pumpLocalizedApp(
      tester,
      BlocProvider.value(
        value: bloc,
        child: const ContractorTaskUpdateStatusPage(
          projectId: 'p-1',
          updateId: 'upd-missing',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsOneWidget);

    repository.taskUpdateResult = Success(buildUpdate());
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('بانتظار مراجعة العميل'), findsOneWidget);
  });

  testWidgets('renders without overflow at 200% bold text scale', (
    tester,
  ) async {
    repository.taskUpdateResult = Success(
      buildUpdate(
        decision: TaskUpdateDecision.rejected,
        rejectionReason: 'الأدلة غير كافية',
        rejectionDetails:
            'لا تظهر زوايا السقف، والتشقق عند النافذة الشرقية ما زال ظاهراً.',
      ),
    );
    final bloc = buildStatusBloc()
      ..add(const ContractorTaskUpdateStatusStarted('upd-1'));
    addTearDown(bloc.close);

    await pumpLocalizedApp(
      tester,
      BlocProvider.value(
        value: bloc,
        child: ContractorTaskUpdateStatusPage(
          projectId: 'p-1',
          updateId: 'upd-1',
          now: sentAtLocal,
        ),
      ),
      textScale: largeTextScale,
      boldText: true,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppStatusCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('registers task_update_accepted and task_update_rejected deep links to status screen', () async {
    await getIt.reset();
    registerContractorTasksDependencies(getIt);
    final link = AppNotificationLinks.linkOf(const {
      'type': 'task_update_rejected',
      'project_id': 'proj-1',
      'update_id': 'upd-99',
    });
    expect(link?.name, ContractorTasksRoutes.taskUpdateStatusName);
    expect(link?.pathParameters, {'projectId': 'proj-1', 'updateId': 'upd-99'});
  });
}
