import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_timeline.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_conversation_page.dart';
import 'package:watad/features/tasks/contractor/contractor_tasks_injection.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_create_task_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_add_task_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_add_task_page.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_project_tasks_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_chat_repository.dart';
import '../../../../helpers/fake_contractor_tasks_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  final inProgressProject = ContractorTaskProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.inProgress,
    ownerName: 'عبدالله الحربي',
    ownerId: 'u-client',
    city: 'الرياض',
    district: 'حي الياسمين',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(9000000),
    totalScheduled: const Money.halalas(21000000),
    createdAt: DateTime.utc(2026, 1, 5),
  );

  final completedProject = ContractorTaskProject(
    id: 'p-1',
    title: 'فيلا سكنية — حي الياسمين',
    status: ProjectStatus.completed,
    ownerName: 'عبدالله الحربي',
    city: 'الرياض',
    district: 'حي الياسمين',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(48000000),
    totalScheduled: const Money.halalas(48000000),
    createdAt: DateTime.utc(2026, 1, 5),
    completedAt: DateTime.utc(2026, 3, 1),
  );

  final scheduleTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'صب الأساسات والخرسانة',
      status: TaskStatus.approved,
      amount: const Money.halalas(9000000),
      paymentStatus: PaymentStatus.paid,
      startDate: DateTime.utc(2026, 1, 10),
      finishDate: DateTime.utc(2026, 1, 18),
      lastUpdateId: 'upd-1',
      createdAt: DateTime.utc(2026, 1, 9),
    ),
    ContractorProjectTask(
      id: 't-2',
      projectId: 'p-1',
      title: 'بناء الجدران والهيكل',
      status: TaskStatus.done,
      amount: const Money.halalas(12000000),
      startDate: DateTime.utc(2026, 1, 20),
      finishDate: DateTime.utc(2026, 1, 26),
      lastUpdateId: 'upd-2',
      createdAt: DateTime.utc(2026, 1, 19),
    ),
    ContractorProjectTask(
      id: 't-3',
      projectId: 'p-1',
      title: 'تمديد الكهرباء والسباكة',
      status: TaskStatus.accepted,
      startDate: DateTime.utc(2026, 1, 27),
      createdAt: DateTime.utc(2026, 1, 27),
    ),
    ContractorProjectTask(
      id: 't-4',
      projectId: 'p-1',
      title: 'أعمال اللياسة والدهان',
      status: TaskStatus.proposed,
      startDate: DateTime.utc(2026, 10, 15),
      createdAt: DateTime.utc(2026, 2, 1),
    ),
    ContractorProjectTask(
      id: 't-5',
      projectId: 'p-1',
      title: 'العزل المائي',
      status: TaskStatus.rejected,
      finishDate: DateTime.utc(2026, 9, 3),
      createdAt: DateTime.utc(2026, 2, 2),
    ),
    ContractorProjectTask(
      id: 't-6',
      projectId: 'p-1',
      title: 'تركيب النوافذ',
      status: TaskStatus.accepted,
      lastUpdateId: 'upd-6',
      lastUpdateDecision: TaskUpdateDecision.rejected,
      createdAt: DateTime.utc(2026, 2, 3),
    ),
  ];

  late FakeContractorTasksRepository repository;

  ContractorProjectTasksBloc buildBloc() => ContractorProjectTasksBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
  );

  ContractorAddTaskBloc buildAddBloc() => ContractorAddTaskBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
    ContractorCreateTaskUseCase(repository),
  );

  setUp(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeContractorTasksRepository()
      ..projectResult = Success(inProgressProject)
      ..tasksResult = Success(scheduleTasks);
    getIt
      ..registerFactory<ContractorProjectTasksBloc>(buildBloc)
      ..registerFactory<ContractorAddTaskBloc>(buildAddBloc);
  });

  tearDown(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
  });

  testWidgets('«مراسلة العميل» opens the chat with the client, about the '
      'project', (tester) async {
    final chat = FakeChatRepository();
    registerFakeChat(chat);
    await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.contractor),
      initialLocation: '/contractor/tasks/p-1',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contractor_project_tasks_message')));
    await tester.pumpAndSettle();

    expect(chat.started, ['u-client p-1']);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    await chat.dispose();
  });

  testWidgets(
    'navigates to /contractor/tasks/:projectId and renders timeline, dates, tags, and summary',
    (tester) async {
      final session = FakeAppSession()..signIn(AppRole.contractor);
      await pumpAppRouter(
        tester,
        session: session,
        initialLocation: '/contractor/tasks/p-1',
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContractorProjectTasksPage), findsOneWidget);
      expect(find.text('فيلا سكنية — حي الياسمين'), findsWidgets);
      expect(find.byType(AppTimeline), findsOneWidget);
      expect(find.text('صب الأساسات والخرسانة'), findsOneWidget);
      expect(find.text('معتمدة ومدفوعة'), findsOneWidget);
      expect(find.text('منجزة — بانتظار اعتماد العميل'), findsOneWidget);
      expect(find.text('مقبولة'), findsOneWidget);
      expect(find.text('مقترحة — بانتظار قبول العميل'), findsOneWidget);
      expect(find.text('مرفوضة'), findsOneWidget);
      expect(find.text('رفض العميل التحديث — يحتاج تعديل'), findsOneWidget);

      // Summary line above bottom buttons shows done + proposed counts.
      expect(
        find.byKey(const Key('contractor_project_tasks_summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('contractor_project_tasks_add')),
        findsOneWidget,
      );
      final updateButton = tester.widget<AppButton>(
        find.byKey(const Key('contractor_project_tasks_update')),
      );
      expect(updateButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'hides bottom action bar when contract is completed (read-only)',
    (tester) async {
      repository.projectResult = Success(completedProject);
      final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));
      addTearDown(bloc.close);

      await pumpLocalizedApp(
        tester,
        BlocProvider.value(
          value: bloc,
          child: ContractorProjectTasksPage(
            projectId: 'p-1',
            today: DateTime.utc(2026, 2, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('contractor_project_tasks_add')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('contractor_project_tasks_update')),
        findsNothing,
      );
    },
  );

  testWidgets('shows empty view when contract has no tasks yet', (
    tester,
  ) async {
    repository.tasksResult = const Success([]);
    final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));
    addTearDown(bloc.close);

    await pumpLocalizedApp(
      tester,
      BlocProvider.value(
        value: bloc,
        child: const ContractorProjectTasksPage(projectId: 'p-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyView), findsOneWidget);
    expect(
      find.byKey(const Key('contractor_project_tasks_summary')),
      findsNothing,
    );
    final updateButton = tester.widget<AppButton>(
      find.byKey(const Key('contractor_project_tasks_update')),
    );
    expect(updateButton.onPressed, isNull);
  });

  testWidgets('shows error view and retries when initial fetch fails', (
    tester,
  ) async {
    repository.projectResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));
    addTearDown(bloc.close);

    await pumpLocalizedApp(
      tester,
      BlocProvider.value(
        value: bloc,
        child: const ContractorProjectTasksPage(projectId: 'p-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsOneWidget);

    repository.projectResult = Success(inProgressProject);
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.byType(AppTimeline), findsOneWidget);
  });

  testWidgets(
    'invokes callbacks for add task, update task, and tapping a task with an update',
    (tester) async {
      String? addedForProject;
      String? updatedForProject;
      String? tappedTaskId;
      final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));
      addTearDown(bloc.close);

      await pumpLocalizedApp(
        tester,
        BlocProvider.value(
          value: bloc,
          child: ContractorProjectTasksPage(
            projectId: 'p-1',
            today: DateTime.utc(2026, 2, 1),
            onAddTask: (_, id) async => addedForProject = id,
            onUpdateTask: (_, id) async => updatedForProject = id,
            onTaskTap: (_, task) async => tappedTaskId = task.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('contractor_project_tasks_add')));
      await tester.pumpAndSettle();
      expect(addedForProject, 'p-1');

      await tester.tap(
        find.byKey(const Key('contractor_project_tasks_update')),
      );
      await tester.pumpAndSettle();
      expect(updatedForProject, 'p-1');

      await tester.tap(find.byKey(const Key('contractor_task_update_t-1')));
      await tester.pumpAndSettle();
      expect(tappedTaskId, 't-1');
    },
  );

  testWidgets(
    'renders schedule page without overflow at 200% bold text scale',
    (tester) async {
      final bloc = buildBloc()..add(const ContractorProjectTasksFetched('p-1'));
      addTearDown(bloc.close);

      await pumpLocalizedApp(
        tester,
        BlocProvider.value(
          value: bloc,
          child: ContractorProjectTasksPage(
            projectId: 'p-1',
            today: DateTime.utc(2026, 2, 1),
          ),
        ),
        textScale: largeTextScale,
        boldText: true,
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(AppTimeline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opens add-task page from schedule, validates inputs, submits new task, and returns to schedule',
    (tester) async {
      final session = FakeAppSession()..signIn(AppRole.contractor);
      await pumpAppRouter(
        tester,
        session: session,
        initialLocation: '/contractor/tasks/p-1',
      );
      await tester.pumpAndSettle();

      // Tap "+ إضافة مهمة" on the schedule page to navigate to GRA-38.
      await tester.tap(find.byKey(const Key('contractor_project_tasks_add')));
      await tester.pumpAndSettle();

      expect(find.byType(ContractorAddTaskPage), findsOneWidget);
      expect(find.text('إضافة مهمة'), findsOneWidget);

      // Submit empty description to trigger validation errors while keeping typed text.
      await tester.enterText(
        find.byKey(const Key('contractor_add_task_title')),
        'عزل السطح المائي والحراري',
      );
      await tester.tap(find.byKey(const Key('contractor_add_task_submit')));
      await tester.pumpAndSettle();

      expect(find.text('وصف المهمة مطلوب'), findsOneWidget);
      expect(find.text('عزل السطح المائي والحراري'), findsOneWidget);

      // Fill description, test exceeding remaining budget, then submit valid amount.
      await tester.enterText(
        find.byKey(const Key('contractor_add_task_description')),
        'طبقتان من العزل البيتوميني مع اختبار غمر ٤٨ ساعة.',
      );
      await tester.enterText(
        find.byKey(const Key('contractor_add_task_amount')),
        '999999',
      );
      await tester.tap(find.byKey(const Key('contractor_add_task_submit')));
      await tester.pumpAndSettle();

      final amountErrorFinder = find.textContaining(
        'المبلغ يتجاوز المتبقي من قيمة العقد',
      );
      expect(amountErrorFinder, findsOneWidget);
      expect(tester.widget<Text>(amountErrorFinder).maxLines, 3);

      await tester.enterText(
        find.byKey(const Key('contractor_add_task_amount')),
        '38000',
      );
      await tester.tap(find.byKey(const Key('contractor_add_task_submit')));
      await tester.pumpAndSettle();

      expect(repository.lastCreatedTask?.title, 'عزل السطح المائي والحراري');
      expect(repository.lastCreatedTask?.amount, Money.fromSar(38000));
      expect(find.byType(ContractorProjectTasksPage), findsOneWidget);
    },
  );

  testWidgets(
    'renders add-task page without overflow at 200% bold text scale',
    (tester) async {
      final bloc = buildAddBloc()..add(const ContractorAddTaskStarted('p-1'));
      addTearDown(bloc.close);

      await pumpLocalizedApp(
        tester,
        BlocProvider.value(
          value: bloc,
          child: const ContractorAddTaskPage(projectId: 'p-1'),
        ),
        textScale: largeTextScale,
        boldText: true,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContractorAddTaskPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('registers contractor task notification deep links', () async {
    await getIt.reset();
    registerContractorTasksDependencies(getIt);
    final link = AppNotificationLinks.linkOf(const {
      'type': 'task_accepted',
      'project_id': 'proj-42',
    });
    expect(link?.name, ContractorTasksRoutes.projectTasksName);
    expect(link?.pathParameters, {'projectId': 'proj-42'});
  });
}
