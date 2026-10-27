import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/components/display/app_state_stepper.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_conversation_page.dart';
import 'package:watad/features/payments/client/presentation/pages/client_new_payment_page.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_tasks_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_deed_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_tasks_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_task_details_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_task_update_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_task_update_reject_page.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_task_date.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_chat_repository.dart';
import '../../../../helpers/fake_client_payments_repository.dart';
import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/fake_network_images.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  final project = ClientProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.open,
    city: 'المدينة المنورة',
    district: 'حي الياسمين',
    budget: const Money.halalas(45000000),
    pendingOfferCount: 1,
    deedStatus: ClientDeedVerificationStatus.verified,
    createdAt: DateTime.utc(2026, 10, 18),
  );
  final rejected = ClientProject(
    id: 'p-2',
    title: 'ترميم الواجهة',
    status: ProjectStatus.draft,
    city: 'المدينة المنورة',
    pendingOfferCount: 0,
    deedStatus: ClientDeedVerificationStatus.rejected,
    deedRejectionReason: 'الصك غير واضح',
    createdAt: DateTime.utc(2026, 10, 19),
  );
  final offer = ClientProjectOffer(
    id: 'o-1',
    projectId: 'p-1',
    providerId: 'u-contractor',
    amount: const Money.halalas(46500000),
    status: OfferStatus.pending,
    providerName: 'مؤسسة البناء المتين',
    isProviderVerified: true,
    providerRatingAvg: 4.8,
    providerRatingCount: 12,
    message: 'يشمل التشطيب الخارجي',
    createdAt: DateTime.utc(2026, 10, 18),
  );
  final started = ClientProject(
    id: 'p-3',
    title: 'بناء ملحق',
    status: ProjectStatus.inProgress,
    city: 'جدة',
    pendingOfferCount: 0,
    contractorName: 'مؤسسة البناء المتين',
    takerId: 'u-contractor',
    createdAt: DateTime.utc(2026, 10, 17),
  );
  // One task in each state, as the contractor's work moves on.
  final tasks = [
    ClientProjectTask(
      id: 't-1',
      title: 'الحفر والأساسات',
      description: 'حفر الموقع وصب الأساسات',
      status: TaskStatus.approved,
      amount: const Money.halalas(2400000),
      paymentStatus: PaymentStatus.paid,
      startDate: DateTime.utc(2026, 10, 1),
      finishDate: DateTime.utc(2026, 10, 8),
      lastUpdateId: 'u-1',
    ),
    ClientProjectTask(
      id: 't-2',
      title: 'الهيكل الخرساني',
      description: 'صب الأعمدة والسقف',
      status: TaskStatus.approved,
      amount: const Money.halalas(3000000),
      paymentStatus: PaymentStatus.processing,
      startDate: DateTime.utc(2026, 10, 9),
      finishDate: DateTime.utc(2026, 10, 11),
      lastUpdateId: 'u-2',
    ),
    ClientProjectTask(
      id: 't-3',
      title: 'اللياسة الداخلية',
      description: 'لياسة الجدران الداخلية',
      status: TaskStatus.done,
      amount: const Money.halalas(1500000),
      startDate: DateTime.utc(2026, 10, 12),
      finishDate: DateTime.utc(2026, 10, 20),
      lastUpdateId: 'u-3',
    ),
    ClientProjectTask(
      id: 't-4',
      title: 'تمديدات الكهرباء',
      description: 'تمديد نقاط الكهرباء',
      status: TaskStatus.accepted,
      amount: const Money.halalas(900000),
      startDate: DateTime.utc(2026, 10, 22),
    ),
    const ClientProjectTask(
      id: 't-5',
      title: 'الدهانات',
      description: 'دهان الجدران الداخلية',
      status: TaskStatus.proposed,
    ),
    const ClientProjectTask(
      id: 't-6',
      title: 'العزل المائي',
      description: 'عزل سطح الملحق',
      status: TaskStatus.rejected,
      amount: Money.halalas(500000),
    ),
  ];
  // The «منجزة» update of t-3, with three evidence photos.
  ClientTaskUpdate taskUpdate([
    TaskUpdateDecision decision = TaskUpdateDecision.pending,
  ]) => ClientTaskUpdate(
    id: 'u-3',
    taskTitle: 'اللياسة الداخلية',
    proposedState: TaskUpdateState.done,
    decision: decision,
    createdAt: DateTime.utc(2026, 10, 24, 6, 40),
    projectStatus: ProjectStatus.inProgress,
    taskAmount: const Money.halalas(1500000),
    note: 'انتهت لياسة الدور الأرضي كاملة',
    photoUrls: [
      for (final photo in ['a', 'b', 'c'])
        'https://example.supabase.co/storage/v1/object/sign/task-evidence/b-1/$photo.jpg?token=t',
    ],
    contractorName: 'مؤسسة البناء المتين',
    rejectionReason: decision == TaskUpdateDecision.rejected
        ? 'الأدلة غير كافية'
        : null,
    rejectionDetails: decision == TaskUpdateDecision.rejected
        ? 'لا تظهر زوايا السقف.'
        : null,
  );

  late FakeClientProjectsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeClientProjectsRepository()
      ..projectsResult = Success([rejected, project])
      ..projectResult = Success(project)
      ..offersResult = Success([offer]);
    registerFakeClientProjects(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openList(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(ClientProjectsRoutes.projectsName);
    await tester.pumpAndSettle();
    return router;
  }

  Future<GoRouter> openTasks(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    repository
      ..projectResult = Success(started)
      ..projectTasksResult = Success(tasks);
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      ClientProjectsRoutes.projectTasksName,
      pathParameters: {'projectId': 'p-3'},
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openOffers(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();
    expect(currentPath(router), '/client/projects/p-1/offers');
  }

  testWidgets('client-post-project opens the post flow at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientProjectsRoutes.postProjectName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientProjectsRoutes.postProjectPath);
    expect(find.byType(ClientPostProjectPage), findsOneWidget);
  });

  testWidgets('client-projects lists the projects at its path', (tester) async {
    final router = await openList(tester);

    expect(currentPath(router), ClientProjectsRoutes.projectsPath);
    expect(find.byType(ClientProjectsPage), findsOneWidget);
    expect(find.text('فيلا سكنية'), findsOneWidget);
    expect(find.text('المدينة المنورة — حي الياسمين'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
    expect(find.text('عرض واحد'), findsOneWidget);
    // A rejected deed says so, with the admin's reason.
    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('سبب رفض الصك: الصك غير واضح'), findsOneWidget);

    // A tap opens its offers.
    await tester.tap(find.text('فيلا سكنية'));
    await tester.pumpAndSettle();
    expect(find.byType(ClientProjectOffersPage), findsOneWidget);
  });

  testWidgets('the chips split the projects: done, waiting, in progress', (
    tester,
  ) async {
    ClientProject withStatus(String id, String title, ProjectStatus status) =>
        ClientProject(
          id: id,
          title: title,
          status: status,
          city: 'جدة',
          pendingOfferCount: 0,
          createdAt: DateTime.utc(2026, 10, 17),
        );
    repository.projectsResult = Success([
      rejected,
      project,
      withStatus('p-3', 'بناء ملحق', ProjectStatus.inProgress),
      withStatus('p-4', 'ترميم مطبخ', ProjectStatus.completed),
    ]);
    await openList(tester);
    Future<void> tapChip(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('client_projects_filter')),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    // It opens on «قيد الانتظار»: waiting for the deed, or for offers.
    expect(find.text('ترميم الواجهة'), findsOneWidget);
    expect(find.text('فيلا سكنية'), findsOneWidget);
    expect(find.text('بناء ملحق'), findsNothing);
    expect(find.text('ترميم مطبخ'), findsNothing);

    await tapChip('قيد التنفيذ');
    expect(find.text('بناء ملحق'), findsOneWidget);
    expect(find.text('فيلا سكنية'), findsNothing);

    await tapChip('مكتملة');
    expect(find.text('ترميم مطبخ'), findsOneWidget);
    expect(find.text('بناء ملحق'), findsNothing);
  });

  testWidgets(
    'started and done projects open their tasks; cancelled, nothing',
    (tester) async {
      ClientProject withStatus(String id, String title, ProjectStatus status) =>
          ClientProject(
            id: id,
            title: title,
            status: status,
            city: 'جدة',
            pendingOfferCount: 0,
            createdAt: DateTime.utc(2026, 10, 17),
          );
      repository
        ..projectsResult = Success([
          withStatus('p-3', 'بناء ملحق', ProjectStatus.inProgress),
          withStatus('p-4', 'ترميم مطبخ', ProjectStatus.completed),
          withStatus('p-5', 'ترميم السور', ProjectStatus.cancelled),
        ])
        ..projectResult = Success(started);
      final router = await openList(tester);
      Future<void> tapChip(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('client_projects_filter')),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      // A pushed page doesn't change the router's location: check which
      // project the page opened for.
      String openedProject() => tester
          .widget<ClientProjectTasksPage>(find.byType(ClientProjectTasksPage))
          .projectId;

      await tapChip('قيد التنفيذ');
      await tester.tap(find.text('بناء ملحق'));
      await tester.pumpAndSettle();
      expect(openedProject(), 'p-3');

      // Back to «مشاريعي», which reads the projects again.
      router.pop();
      await tester.pumpAndSettle();
      await tapChip('مكتملة');
      await tester.tap(find.text('ترميم مطبخ'));
      await tester.pumpAndSettle();
      expect(openedProject(), 'p-4');

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('ترميم السور'));
      await tester.pumpAndSettle();
      expect(find.byType(ClientProjectTasksPage), findsNothing);
      expect(find.byType(ClientProjectsPage), findsOneWidget);
    },
  );

  testWidgets(
    'client-project-tasks shows the tasks as a timeline at its path',
    (tester) async {
      final router = await openTasks(tester);

      expect(currentPath(router), '/client/projects/p-3');
      expect(find.byType(ClientProjectTasksPage), findsOneWidget);
      expect(find.text('بناء ملحق'), findsOneWidget);
      expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
      // Every state reads as the issue says.
      expect(find.text('مكتملة ومعتمدة'), findsNWidgets(2));
      expect(find.text('مدفوعة'), findsOneWidget);
      expect(find.text('بانتظار تأكيد المقاول'), findsOneWidget);
      expect(find.text('بانتظار موافقتك'), findsOneWidget);
      expect(find.text('قيد التنفيذ'), findsOneWidget);
      expect(find.text('مقترحة — بانتظار قبولك'), findsOneWidget);
      expect(find.text('مرفوضة'), findsOneWidget);
      // Amounts and dates.
      expect(find.text('٢٤٬٠٠٠ ر.س'), findsOneWidget);
      expect(find.text('بلا مبلغ'), findsOneWidget);
      final context = tester.element(find.byType(ClientProjectTasksPage));
      expect(
        find.text(
          ClientTaskDate.days(
            context,
            DateTime.utc(2026, 10, 12),
            DateTime.utc(2026, 10, 20),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          ClientTaskDate.days(context, DateTime.utc(2026, 10, 22), null),
        ),
        findsOneWidget,
      );
      expect(find.text('بلا موعد بعد'), findsNWidgets(2));
      // «التفاصيل» beside each task and «الدفع للمقاول» at the bottom: no
      // approve or reject buttons on this screen.
      expect(find.widgetWithText(AppButton, 'التفاصيل'), findsNWidgets(6));
      expect(find.byKey(const Key('client_project_tasks_pay')), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(7));
    },
  );

  testWidgets('a project without tasks says so', (tester) async {
    await openTasks(tester);
    repository.projectTasksResult = const Success([]);
    tester
        .element(find.byType(ClientProjectTasksPage))
        .read<ClientProjectTasksBloc>()
        .add(const ClientProjectTasksFetched('p-3'));
    await tester.pumpAndSettle();

    expect(find.text('لم يضف المقاول مهام لهذا المشروع بعد'), findsOneWidget);
  });

  testWidgets('a chip without projects says so', (tester) async {
    await openList(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('client_projects_filter')),
        matching: find.text('مكتملة'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا مشاريع هنا بعد'), findsOneWidget);
  });

  testWidgets('a card shows the photo and the tasks\' progress', (
    tester,
  ) async {
    repository.projectsResult = Success([
      ClientProject(
        id: 'p-3',
        title: 'بناء ملحق',
        status: ProjectStatus.inProgress,
        city: 'جدة',
        pendingOfferCount: 0,
        photoUrl: 'https://example.supabase.co/storage/v1/object/public/images/u-1/projects/a.png',
        contractorName: 'مؤسسة البناء المتين',
        agreedAmount: const Money.halalas(46500000),
        taskCount: 4,
        approvedTaskCount: 2,
        createdAt: DateTime.utc(2026, 10, 17),
      ),
    ]);
    await openList(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('client_projects_filter')),
        matching: find.text('قيد التنفيذ'),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byType(AppProjectCard);
    expect(
      tester.widget<AppProjectCard>(card).imageUrl,
      endsWith('/images/u-1/projects/a.png'),
    );
    expect(find.text('٢ من ٤ مهام'), findsOneWidget);
    expect(find.text('٥٠٪'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: card,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      0.5,
    );
    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('٤٦٥٬٠٠٠ ر.س'), findsOneWidget);
  });

  testWidgets('a waiting project shows no progress, and its placeholder', (
    tester,
  ) async {
    await openList(tester);

    // Waiting for the deed or for offers: no work to measure yet.
    expect(find.text('قيد التخطيط'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppProjectCard),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );
    // No photo: the striped placeholder.
    expect(
      tester
          .widgetList<AppProjectCard>(find.byType(AppProjectCard))
          .map((card) => card.imageUrl),
      everyElement(isNull),
    );
  });

  testWidgets('started without tasks yet: «قيد التخطيط»', (tester) async {
    repository.projectsResult = Success([
      ClientProject(
        id: 'p-3',
        title: 'بناء ملحق',
        status: ProjectStatus.inProgress,
        city: 'جدة',
        pendingOfferCount: 0,
        contractorName: 'مؤسسة البناء المتين',
        createdAt: DateTime.utc(2026, 10, 17),
      ),
    ]);
    await openList(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('client_projects_filter')),
        matching: find.text('قيد التنفيذ'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('قيد التخطيط'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppProjectCard),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );
  });

  testWidgets('no projects yet offers to post one', (tester) async {
    repository.projectsResult = const Success([]);
    await openList(tester);

    expect(find.text('لم تنشر أي مشروع بعد'), findsOneWidget);
    await tester.tap(find.byKey(const Key('client_projects_post_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ClientPostProjectPage), findsOneWidget);
  });

  testWidgets('client-project-offers shows the offers as in the design', (
    tester,
  ) async {
    await openOffers(tester);

    expect(find.text('فيلا سكنية — حي الياسمين'), findsOneWidget);
    expect(find.text('عرض واحد'), findsOneWidget);
    expect(find.text('الميزانية المعلنة ٤٥٠٬٠٠٠ ر.س'), findsOneWidget);
    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('٤٫٨'), findsOneWidget);
    expect(find.text('يشمل التشطيب الخارجي'), findsOneWidget);
  });

  testWidgets('the project screen messages its contractor', (tester) async {
    final chat = FakeChatRepository();
    registerFakeChat(chat);
    await openTasks(tester);

    await tester.tap(find.byKey(const Key('client_project_tasks_message')));
    await tester.pumpAndSettle();

    expect(chat.started, ['u-contractor p-3']);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    await chat.dispose();
  });

  testWidgets('a project without a contractor has no message button', (
    tester,
  ) async {
    repository.projectResult = Success(project);
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.projectTasksName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('client_project_tasks_message')), findsNothing);
  });

  testWidgets('«مراسلة» opens the chat with that contractor, about the '
      'project', (tester) async {
    final chat = FakeChatRepository();
    registerFakeChat(chat);
    await openOffers(tester);

    await tester.tap(find.widgetWithText(AppButton, 'مراسلة'));
    await tester.pumpAndSettle();

    expect(chat.started, ['u-contractor p-1']);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    await chat.dispose();
  });

  testWidgets('accepting asks first, then accepts at the amount shown', (
    tester,
  ) async {
    await openOffers(tester);

    await tester.tap(find.widgetWithText(AppButton, 'قبول العرض'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(repository.accepted, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text('قبول العرض'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.accepted, [('o-1', 46500000)]);
  });

  testWidgets('no offers yet', (tester) async {
    repository.offersResult = const Success([]);
    await openOffers(tester);

    expect(find.text('لم تصل عروض على هذا المشروع بعد'), findsOneWidget);
  });

  testWidgets('a rejected deed opens client-project-deed to send a new one', (
    tester,
  ) async {
    repository.projectResult = Success(rejected);
    await openList(tester);

    await tester.tap(find.text('ترميم الواجهة'));
    await tester.pumpAndSettle();
    expect(find.byType(ClientProjectDeedPage), findsOneWidget);
    expect(find.text('الصك غير واضح'), findsOneWidget);
    // Nothing to send before a file is picked.
    final send = find.byKey(const Key('client_project_deed_send'));
    expect(tester.widget<AppButton>(send).onPressed, isNull);

    // The phone's file picker isn't in tests: the bloc gets the file.
    tester
        .element(find.byType(ClientProjectDeedPage))
        .read<ClientProjectDeedBloc>()
        .add(
          const ClientProjectDeedPicked(
            filePath: '/tmp/deed.pdf',
            fileName: 'deed.pdf',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('تم اختيار الملف: deed.pdf'), findsOneWidget);

    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(repository.replacedDeeds, [('p-2', '/tmp/deed.pdf')]);
    // Sent: back to the list.
    expect(find.byType(ClientProjectDeedPage), findsNothing);
    expect(find.byType(ClientProjectsPage), findsOneWidget);
  });

  testWidgets('a deed that is no longer rejected has nothing to send', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.projectDeedName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/client/projects/p-1/deed');
    expect(find.text('لا يحتاج هذا المشروع إلى صك جديد'), findsOneWidget);
    expect(find.byKey(const Key('client_project_deed_pick')), findsNothing);
  });

  test('a project\'s notifications open its screens', () {
    AppNotificationLink? linkOf(String type) =>
        AppNotificationLinks.linkOf({'type': type, 'project_id': 'p-1'});

    expect(
      linkOf('offer_received')?.name,
      ClientProjectsRoutes.projectOffersName,
    );
    expect(
      linkOf('deed_verified')?.name,
      ClientProjectsRoutes.projectOffersName,
    );
    expect(linkOf('deed_rejected')?.name, ClientProjectsRoutes.projectDeedName);
    expect(linkOf('offer_received')?.pathParameters, {'projectId': 'p-1'});
    expect(linkOf('task_added')?.name, ClientProjectsRoutes.projectTasksName);
    expect(linkOf('task_added')?.pathParameters, {'projectId': 'p-1'});
    final update = AppNotificationLinks.linkOf({
      'type': 'task_update_sent',
      'project_id': 'p-1',
      'task_id': 't-1',
      'update_id': 'u-1',
    });
    expect(update?.name, ClientProjectsRoutes.taskUpdateName);
    expect(update?.pathParameters, {'projectId': 'p-1', 'updateId': 'u-1'});
  });

  testWidgets('every projects page fits large, bold text', (tester) async {
    final router = await openList(
      tester,
      textScale: largeTextScale,
      boldText: true,
    );
    expect(tester.takeException(), isNull);

    router.goNamed(
      ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    repository.projectResult = Success(rejected);
    router.goNamed(
      ClientProjectsRoutes.projectDeedName,
      pathParameters: {'projectId': 'p-2'},
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tasks timeline fits large, bold text', (tester) async {
    await openTasks(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(ClientProjectTasksPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<GoRouter> openUpdate(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      ClientProjectsRoutes.taskUpdateName,
      pathParameters: {'projectId': 'p-3', 'updateId': 'u-3'},
    );
    await tester.pumpAndSettle();
    return router;
  }

  // Opens a task's «التفاصيل» on the timeline, as the client does.
  Future<void> openDetails(WidgetTester tester, String taskId) async {
    final details = find.byKey(ValueKey('client_task_details_$taskId'));
    await tester.ensureVisible(details);
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();
  }

  testWidgets('client-task-update shows the update at its path', (
    tester,
  ) async {
    repository.taskUpdateResult = Success(taskUpdate());
    await withFakeNetworkImages(() async {
      final router = await openUpdate(tester);

      expect(currentPath(router), '/client/projects/p-3/updates/u-3');
      expect(find.byType(ClientTaskUpdatePage), findsOneWidget);
      expect(find.text('اللياسة الداخلية'), findsOneWidget);
      expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
      expect(find.text('انتهت لياسة الدور الأرضي كاملة'), findsOneWidget);
      expect(find.byType(AppPhotoTile), findsNWidgets(3));
      expect(find.text('١٥٬٠٠٠ ر.س'), findsOneWidget);
      // The status filled in up to «منجزة».
      expect(
        tester.widget<AppStateStepper>(find.byType(AppStateStepper)),
        isA<AppStateStepper>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having((s) => s.animateFrom, 'animateFrom', 0),
      );
      expect(
        find.byKey(const Key('client_task_update_accept')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('client_task_update_reject')),
        findsOneWidget,
      );
    });
  });

  testWidgets('accepting approves the task; the status fills to «معتمدة»', (
    tester,
  ) async {
    repository
      ..taskUpdateResult = Success(taskUpdate())
      ..taskUpdateAfterAccept = Success(
        taskUpdate(TaskUpdateDecision.accepted),
      );
    await withFakeNetworkImages(() async {
      await openUpdate(tester);
      await tester.tap(find.byKey(const Key('client_task_update_accept')));
      await tester.pumpAndSettle();

      expect(repository.acceptedUpdates, ['u-3']);
      expect(find.text('اعتُمدت المهمة'), findsOneWidget);
      expect(find.text('اعتمدتَ هذه المهمة'), findsOneWidget);
      expect(
        tester
            .widget<AppStateStepper>(find.byType(AppStateStepper))
            .currentIndex,
        2,
      );
      expect(find.byKey(const Key('client_task_update_accept')), findsNothing);
    });
  });

  testWidgets('a rejected update only reads, with the client\'s reason', (
    tester,
  ) async {
    repository.taskUpdateResult = Success(
      taskUpdate(TaskUpdateDecision.rejected),
    );
    await withFakeNetworkImages(() async {
      await openUpdate(tester);

      expect(find.text('رفضتَ هذا التحديث'), findsOneWidget);
      expect(
        find.text('الأدلة غير كافية\nلا تظهر زوايا السقف.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('client_task_update_accept')), findsNothing);
      expect(find.byKey(const Key('client_task_update_reject')), findsNothing);
    });
  });

  testWidgets(
    'a task with updates opens its latest one; the others, the task',
    (tester) async {
      repository
        ..taskUpdateResult = Success(taskUpdate())
        ..projectTaskResult = Success(tasks[4]);
      await withFakeNetworkImages(() async {
        final router = await openTasks(tester);

        await openDetails(tester, 't-3');
        expect(
          tester
              .widget<ClientTaskUpdatePage>(find.byType(ClientTaskUpdatePage))
              .updateId,
          'u-3',
        );

        router.pop();
        await tester.pumpAndSettle();
        await openDetails(tester, 't-5');
        expect(
          tester
              .widget<ClientTaskDetailsPage>(find.byType(ClientTaskDetailsPage))
              .taskId,
          't-5',
        );
      });
    },
  );

  testWidgets('accepting a proposed task goes back to the timeline', (
    tester,
  ) async {
    repository.projectTaskResult = Success(tasks[4]);
    await openTasks(tester);
    await openDetails(tester, 't-5');
    expect(find.text('دهان الجدران الداخلية'), findsOneWidget);
    // Short labels, so both fit the action bar.
    for (final (key, label) in [
      ('client_task_accept', 'قبول'),
      ('client_task_reject', 'رفض'),
    ]) {
      expect(
        find.descendant(of: find.byKey(Key(key)), matching: find.text(label)),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const Key('client_task_accept')));
    await tester.pumpAndSettle();

    expect(repository.taskStatuses, [('t-5', TaskStatus.accepted)]);
    expect(find.text('قُبلت المهمة'), findsOneWidget);
    expect(find.byType(ClientTaskDetailsPage), findsNothing);
    expect(find.byType(ClientProjectTasksPage), findsOneWidget);
  });

  testWidgets('rejecting a proposed task asks first', (tester) async {
    repository.projectTaskResult = Success(tasks[4]);
    await openTasks(tester);
    await openDetails(tester, 't-5');

    await tester.tap(find.byKey(const Key('client_task_reject')));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(repository.taskStatuses, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text('رفض المهمة'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.taskStatuses, [('t-5', TaskStatus.rejected)]);
    expect(find.text('رُفضت المهمة'), findsOneWidget);
    expect(find.byType(ClientProjectTasksPage), findsOneWidget);
  });

  testWidgets('client-task-details only reads a task that is not proposed', (
    tester,
  ) async {
    repository
      ..projectResult = Success(started)
      ..projectTaskResult = Success(tasks[3]);
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.taskDetailsName,
      pathParameters: {'projectId': 'p-3', 'taskId': 't-4'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/client/projects/p-3/tasks/t-4');
    expect(find.text('تمديد نقاط الكهرباء'), findsOneWidget);
    expect(find.text('قيد التنفيذ'), findsOneWidget);
    expect(find.text('٩٬٠٠٠ ر.س'), findsOneWidget);
    expect(find.byKey(const Key('client_task_accept')), findsNothing);
    expect(find.byKey(const Key('client_task_reject')), findsNothing);
  });

  testWidgets('the update and task pages fit large, bold text', (tester) async {
    repository
      ..taskUpdateResult = Success(taskUpdate())
      ..projectResult = Success(started)
      ..projectTaskResult = Success(tasks[4]);
    await withFakeNetworkImages(() async {
      final router = await openUpdate(
        tester,
        textScale: largeTextScale,
        boldText: true,
      );
      expect(find.byType(ClientTaskUpdatePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      router.goNamed(
        ClientProjectsRoutes.taskDetailsName,
        pathParameters: {'projectId': 'p-3', 'taskId': 't-5'},
      );
      await tester.pumpAndSettle();
      expect(find.byType(ClientTaskDetailsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // The send button of the rejection form.
  Finder rejectSend() => find.widgetWithText(AppButton, 'إرسال الرفض للمقاول');

  testWidgets('client-task-update-reject opens the form at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.taskUpdateRejectName,
      pathParameters: {'projectId': 'p-3', 'updateId': 'u-3'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/client/projects/p-3/updates/u-3/reject');
    expect(find.byType(ClientTaskUpdateRejectPage), findsOneWidget);
    for (final reason in [
      'الأدلة غير كافية',
      'العمل غير مكتمل',
      'الجودة لا تطابق المتفق عليه',
      'الحالة غير صحيحة',
      'أخرى',
    ]) {
      expect(find.text(reason), findsOneWidget);
    }

    // Nothing to send before a reason and the details.
    expect(tester.widget<AppButton>(rejectSend()).onPressed, isNull);
    await tester.tap(find.text('العمل غير مكتمل'));
    await tester.pump();
    expect(tester.widget<AppButton>(rejectSend()).onPressed, isNull);
    await tester.enterText(
      find.byType(TextFormField),
      'لم تكتمل الواجهة الشرقية',
    );
    await tester.pump();
    expect(tester.widget<AppButton>(rejectSend()).onPressed, isNotNull);
  });

  testWidgets('rejecting sends the reason as read, then back to the timeline', (
    tester,
  ) async {
    repository.taskUpdateResult = Success(taskUpdate());
    await withFakeNetworkImages(() async {
      await openTasks(tester);
      await openDetails(tester, 't-3');
      await tester.tap(find.byKey(const Key('client_task_update_reject')));
      await tester.pumpAndSettle();
      expect(find.byType(ClientTaskUpdateRejectPage), findsOneWidget);

      await tester.tap(find.text('الأدلة غير كافية'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField),
        '  لا تظهر زوايا السقف في الصور  ',
      );
      await tester.pump();
      await tester.ensureVisible(rejectSend());
      await tester.pumpAndSettle();
      await tester.tap(rejectSend());
      await tester.pumpAndSettle();

      expect(repository.rejections, [
        ('u-3', 'الأدلة غير كافية', 'لا تظهر زوايا السقف في الصور'),
      ]);
      expect(find.text('أُرسل الرفض للمقاول'), findsOneWidget);
      // Both pages closed: the timeline reads the tasks again.
      expect(find.byType(ClientTaskUpdateRejectPage), findsNothing);
      expect(find.byType(ClientTaskUpdatePage), findsNothing);
      expect(find.byType(ClientProjectTasksPage), findsOneWidget);
    });
  });

  testWidgets('a refused rejection stays on the form and says why', (
    tester,
  ) async {
    repository
      ..taskUpdateResult = Success(taskUpdate())
      ..rejectTaskUpdateResult = const Failed(ConflictFailure());
    await withFakeNetworkImages(() async {
      await openTasks(tester);
      await openDetails(tester, 't-3');
      await tester.tap(find.byKey(const Key('client_task_update_reject')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('الحالة غير صحيحة'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'المهمة لم تبدأ');
      await tester.pump();
      await tester.ensureVisible(rejectSend());
      await tester.pumpAndSettle();
      await tester.tap(rejectSend());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'تغيّرت البيانات في هذه الأثناء. حدّث الصفحة وحاول مرة أخرى.',
        ),
        findsOneWidget,
      );
      // Still on the form, with what the client wrote.
      expect(find.byType(ClientTaskUpdateRejectPage), findsOneWidget);
      expect(find.text('المهمة لم تبدأ'), findsOneWidget);
    });
  });

  testWidgets('the reject page fits large, bold text', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: largeTextScale,
      boldText: true,
    );
    router.goNamed(
      ClientProjectsRoutes.taskUpdateRejectName,
      pathParameters: {'projectId': 'p-3', 'updateId': 'u-3'},
    );
    await tester.pumpAndSettle();

    expect(find.byType(ClientTaskUpdateRejectPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«الدفع للمقاول» opens the choice of tasks to pay', (
    tester,
  ) async {
    registerFakeClientPayments();
    await openTasks(tester);

    await tester.tap(find.byKey(const Key('client_project_tasks_pay')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ClientNewPaymentPage>(find.byType(ClientNewPaymentPage))
          .projectId,
      'p-3',
    );
  });
}
