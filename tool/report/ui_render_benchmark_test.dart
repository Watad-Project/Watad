// Measures how long the main screens take to render, for the testing
// results page (report section 5.5.1, GRA-74). It is not part of
// `flutter test`: tool/report/make_report.dart runs it on its own and reads
// what it writes to build/report/bench.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_blockchain_routes.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/router/routes/settings_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/tasks/contractor/contractor_tasks_injection.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

import '../../test/helpers/fake_admin_blockchain_repository.dart';
import '../../test/helpers/fake_app_session.dart';
import '../../test/helpers/fake_chat_repository.dart';
import '../../test/helpers/fake_client_home_repository.dart';
import '../../test/helpers/fake_client_projects_repository.dart';
import '../../test/helpers/fake_contractor_tasks_repository.dart';
import '../../test/helpers/fake_marketplace_repository.dart';
import '../../test/helpers/fake_profile_repository.dart';
import '../../test/helpers/fake_splash_repository.dart';
import '../../test/helpers/pump_router.dart';

/// How many times each screen opens; the page shows the median and the 95th
/// percentile of these runs.
const int runs = 20;

/// One JSON line per screen. make_report.dart empties it before a run.
const String benchFile = 'build/report/bench.json';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 120 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> measure(
  WidgetTester tester,
  String screen,
  AppRole role,
  void Function(GoRouter router) open,
) async {
  final router = await pumpAppRouter(
    tester,
    session: FakeAppSession()..signIn(role),
  );
  void away() => router.goNamed(
    SettingsRoutes.settingsInfoName,
    pathParameters: {'page': 'about'},
  );
  away();
  await settle(tester);
  final first = <double>[];
  final full = <double>[];
  // One warm-up run, not counted, like a screen opened a second time.
  for (var i = 0; i <= runs; i++) {
    final watch = Stopwatch()..start();
    open(router);
    await tester.pump();
    final firstFrame = watch.elapsedMicroseconds / 1000;
    await settle(tester);
    final done = watch.elapsedMicroseconds / 1000;
    if (i > 0) {
      first.add(firstFrame);
      full.add(done);
    }
    away();
    await settle(tester);
  }
  File(benchFile)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${jsonEncode({'screen': screen, 'first': first, 'full': full})}\n',
      mode: FileMode.append,
    );
}

void main() {
  final contractorProject = ContractorTaskProject(
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
  final contractorTasks = [
    for (var i = 0; i < 8; i++)
      ContractorProjectTask(
        id: 't-$i',
        projectId: 'p-1',
        title: 'مهمة رقم ${i + 1}',
        status: TaskStatus.values[i % TaskStatus.values.length],
        amount: const Money.halalas(3000000),
        paymentStatus: i == 0 ? PaymentStatus.paid : null,
        startDate: DateTime.utc(2026, 1, 10 + i),
        finishDate: DateTime.utc(2026, 1, 18 + i),
        createdAt: DateTime.utc(2026, 1, 5 + i),
      ),
  ];
  final clientProject = ClientProject(
    id: 'p-3',
    title: 'بناء ملحق',
    status: ProjectStatus.inProgress,
    city: 'جدة',
    pendingOfferCount: 0,
    contractorName: 'مؤسسة البناء المتين',
    takerId: 'u-contractor',
    createdAt: DateTime.utc(2026, 10, 17),
  );
  final clientTasks = [
    for (var i = 0; i < 8; i++)
      ClientProjectTask(
        id: 't-$i',
        title: 'مهمة رقم ${i + 1}',
        description: 'وصف المهمة',
        status: TaskStatus.values[i % TaskStatus.values.length],
        amount: const Money.halalas(2400000),
        startDate: DateTime.utc(2026, 10, 1 + i),
        finishDate: DateTime.utc(2026, 10, 8 + i),
        lastUpdateId: 'u-$i',
      ),
  ];

  setUp(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
  });

  void useContractorTasks() {
    registerContractorTasksDependencies(getIt);
    getIt
      ..unregister<ContractorTasksRepository>()
      ..registerSingleton<ContractorTasksRepository>(
        FakeContractorTasksRepository()
          ..projectResult = Success(contractorProject)
          ..tasksResult = Success(contractorTasks),
      );
  }

  testWidgets('client home', (tester) async {
    registerFakeClientHome();
    await measure(tester, 'Client home', AppRole.client, (r) {
      r.goNamed(ClientNavigationRoutes.navigationName);
    });
  });

  testWidgets('client project tasks', (tester) async {
    registerFakeClientProjects(
      FakeClientProjectsRepository()
        ..projectResult = Success(clientProject)
        ..projectTasksResult = Success(clientTasks),
    );
    await measure(tester, 'Project tasks (client)', AppRole.client, (r) {
      r.goNamed(
        ClientProjectsRoutes.projectTasksName,
        pathParameters: {'projectId': 'p-3'},
      );
    });
  });

  testWidgets('contractor job', (tester) async {
    useContractorTasks();
    await measure(tester, 'Project schedule (contractor)', AppRole.contractor, (
      r,
    ) {
      r.goNamed(
        ContractorTasksRoutes.projectTasksName,
        pathParameters: {'projectId': 'p-1'},
      );
    });
  });

  testWidgets('add task', (tester) async {
    useContractorTasks();
    await measure(tester, 'Add a task', AppRole.contractor, (r) {
      r.goNamed(
        ContractorTasksRoutes.addTaskName,
        pathParameters: {'projectId': 'p-1'},
      );
    });
  });

  testWidgets('task update', (tester) async {
    useContractorTasks();
    await measure(tester, 'Send a task update', AppRole.contractor, (r) {
      r.goNamed(
        ContractorTasksRoutes.taskUpdateName,
        pathParameters: {'projectId': 'p-1'},
      );
    });
  });

  testWidgets('marketplace', (tester) async {
    registerFakeMarketplace();
    await measure(tester, 'Marketplace', AppRole.client, (r) {
      r.goNamed(MarketplaceRoutes.marketplaceName);
    });
  });

  testWidgets('chat', (tester) async {
    final chat = FakeChatRepository();
    registerFakeChat(chat);
    await measure(tester, 'Chat conversation', AppRole.client, (r) {
      r.goNamed(
        ChatRoutes.chatConversationName,
        pathParameters: {'chatId': fakeChatId},
      );
    });
    await chat.dispose();
  });

  testWidgets('public profile', (tester) async {
    registerFakePublicProfile();
    await measure(tester, 'Public profile', AppRole.client, (r) {
      r.goNamed(
        ProfileRoutes.publicProfileName,
        pathParameters: {'userId': fakePublicProfile.id},
      );
    });
  });

  testWidgets('admin blockchain', (tester) async {
    registerFakeAdminBlockchain(FakeAdminBlockchainRepository());
    await measure(tester, 'Admin blockchain monitor', AppRole.admin, (r) {
      r.goNamed(AdminBlockchainRoutes.blockchainName);
    });
  });
}
