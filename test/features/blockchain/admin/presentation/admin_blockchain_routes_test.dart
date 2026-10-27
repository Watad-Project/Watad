import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_blockchain_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health_problem.dart';
import 'package:watad/features/blockchain/admin/presentation/pages/admin_blockchain_page.dart';
import 'package:watad/features/blockchain/admin/presentation/pages/admin_blockchain_project_page.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_project_card.dart';

import '../../../../helpers/fake_admin_blockchain_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAdminBlockchainRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminBlockchainRepository();
    registerFakeAdminBlockchain(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openMonitor(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(AdminBlockchainRoutes.blockchainName);
    await tester.pumpAndSettle();
    return router;
  }

  Future<GoRouter> openProject(
    WidgetTester tester, {
    String projectId = 'p-failed',
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      AdminBlockchainRoutes.blockchainProjectName,
      pathParameters: {'projectId': projectId},
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('admin-blockchain opens the monitor at its path', (tester) async {
    final router = await openMonitor(tester);

    expect(currentPath(router), AdminBlockchainRoutes.blockchainPath);
    expect(find.byType(AdminBlockchainPage), findsOneWidget);
    // A project needs attention: the overall card is red.
    expect(
      find.descendant(
        of: find.byKey(const Key('admin_blockchain_overall')),
        matching: find.text('يحتاج مراجعة'),
      ),
      findsOneWidget,
    );
    expect(find.text('متصل'), findsOneWidget);
    expect(find.text('فحص الآن'), findsOneWidget);
    expect(repository.healthChecks, 1);
  });

  testWidgets('the projects show those that need attention first', (
    tester,
  ) async {
    await openMonitor(tester);
    await tester.ensureVisible(find.byType(AdminBlockchainProjectCard).first);
    await tester.pumpAndSettle();

    final titles = tester
        .widgetList<AdminBlockchainProjectCard>(
          find.byType(AdminBlockchainProjectCard),
        )
        .map((card) => card.project.title);
    expect(titles, ['بناء ملحق', 'فيلا سكنية']);
    // The client without a name, and the start of the last error.
    expect(find.text('العميل: بلا اسم'), findsOneWidget);
    expect(
      find.textContaining('project created was refused (400)'),
      findsOneWidget,
    );
  });

  testWidgets('a chip shows the projects of its state', (tester) async {
    await openMonitor(tester);
    await tester.ensureVisible(find.text('متزامنة ١'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('متزامنة ١'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminBlockchainProjectCard), findsOneWidget);
    expect(find.text('فيلا سكنية'), findsOneWidget);
  });

  testWidgets('a ledger that does not answer says why', (tester) async {
    repository.healthResult = Success(
      AdminBlockchainHealth(
        isReachable: false,
        checkedAt: DateTime.utc(2026, 10, 27, 8, 30),
        problem: AdminBlockchainHealthProblem.timeout,
      ),
    );
    await openMonitor(tester);

    expect(find.text('غير متصل'), findsOneWidget);
    expect(find.text('انتهت المهلة'), findsOneWidget);
    expect(find.textContaining('الشبكة غير متصلة'), findsOneWidget);
  });

  testWidgets('«فحص الآن» checks the ledger again', (tester) async {
    await openMonitor(tester);

    await tester.tap(find.text('فحص الآن'));
    await tester.pumpAndSettle();

    expect(repository.healthChecks, 2);
  });

  testWidgets('a monitor that cannot load offers to try again', (tester) async {
    repository.overviewResult = const Failed(NetworkFailure());
    await openMonitor(tester);

    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('a tap on a project opens its sync page', (tester) async {
    await openMonitor(tester);
    await tester.ensureVisible(find.text('بناء ملحق'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('بناء ملحق'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminBlockchainProjectPage), findsOneWidget);
  });

  testWidgets('admin-blockchain-project opens the project at its path', (
    tester,
  ) async {
    final router = await openProject(tester);

    expect(currentPath(router), '/admin/blockchain/p-failed');
    expect(find.byType(AdminBlockchainProjectPage), findsOneWidget);
    expect(find.byType(AppStatusCard), findsOneWidget);
    // Why a person has to look, and the full last message.
    expect(
      find.textContaining('البلوك تشين يحفظ الدفعات إلى الأبد'),
      findsOneWidget,
    );
    expect(
      find.text(
        'project created was refused (400): project: "owner" is required '
        'and must be a non-empty string',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the resync asks first, then is sent and reloads', (
    tester,
  ) async {
    await openProject(tester);
    // The button is under the details, past what the list builds at first.
    await tester.dragUntilVisible(
      find.text('إعادة المزامنة الآن'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('إعادة المزامنة الآن'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(repository.resynced, isEmpty);

    await tester.tap(find.text('إعادة المزامنة الآن'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text('إعادة المزامنة الآن'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.resynced, ['p-failed']);
    expect(find.text('أُرسلت إعادة المزامنة'), findsOneWidget);

    // The page reads the project again once the sync had time to run.
    await tester.pump(AdminBlockchainProjectPage.refreshAfterResync);
    await tester.pumpAndSettle();
  });

  testWidgets('a project that is not contracted says so', (tester) async {
    await openProject(tester, projectId: 'p-unknown');

    expect(find.text('هذا المشروع غير متعاقد عليه'), findsOneWidget);
  });

  testWidgets('the monitor fits large bold text', (tester) async {
    await openMonitor(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(AdminBlockchainPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the project page fits large bold text', (tester) async {
    await openProject(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(AdminBlockchainProjectPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
