import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_donut_chart.dart';
import 'package:watad/core/components/display/app_meter.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_dashboard_routes.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/supabase/app_presence.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/blockchain/admin/presentation/pages/admin_blockchain_page.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_tab.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_page.dart';

import '../../../../helpers/fake_admin_blockchain_repository.dart';
import '../../../../helpers/fake_admin_dashboard_repository.dart';
import '../../../../helpers/fake_admin_reports_repository.dart';
import '../../../../helpers/fake_admin_review_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAdminDashboardRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminDashboardRepository();
    registerFakeAdminDashboard(repository);
    registerFakeAdminReview(FakeAdminReviewRepository());
    registerFakeAdminReports(FakeAdminReportsRepository());
    registerFakeAdminBlockchain(FakeAdminBlockchainRepository());
  });

  tearDown(getIt.reset);

  testWidgets('admin-dashboard opens the numbers at its path', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    expect(currentPath(router), AdminDashboardRoutes.dashboardPath);
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    // It opens on what waits for review.
    expect(find.text('رخص بانتظار التوثيق'), findsOneWidget);
    expect(find.text('٧'), findsOneWidget);
  });

  testWidgets('the chips switch to the users, projects and market charts', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('المستخدمون'));
    await tester.pumpAndSettle();
    // Who is online now, and who can sign in.
    expect(find.text('متصلون الآن'), findsOneWidget);
    expect(find.text('٣٧'), findsOneWidget);
    // Arabic-Indic digits with separators: the active users, and the
    // clients and businesses in the middle of the ring.
    expect(find.text('١٬٢١٠'), findsOneWidget);
    expect(find.text('١٬٢٤٠'), findsOneWidget);
    expect(find.byType(AppDonutChart), findsOneWidget);
    // 980 clients of 1,240 users.
    expect(find.text('٩٨٠، ٧٩٪'), findsOneWidget);
    expect(find.text('٢١٢ من ٢٦٠'), findsOneWidget);

    await tester.tap(find.text('المشاريع').first);
    await tester.pumpAndSettle();
    expect(find.text('المشاريع حسب الحالة'), findsOneWidget);
    // 219 of 418 projects are completed.
    expect(find.text('٢١٩، ٥٢٪'), findsOneWidget);

    await tester.tap(find.text('السوق'));
    await tester.pumpAndSettle();
    expect(find.byType(AppMeter), findsOneWidget);
    expect(find.text('٥٨٨، ٩٢٪'), findsOneWidget);
    // 640 listed, 588 on the market.
    expect(find.text('٥٢'), findsOneWidget);
  });

  testWidgets('admins land on it, and it reads again each time it shows', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(repository.reads, 1);

    Finder tab(int index) => find
        .descendant(
          of: find.byType(AppBottomNav),
          matching: find.byType(InkWell),
        )
        .at(index);
    await tester.tap(tab(1));
    await tester.pumpAndSettle();
    expect(repository.reads, 1);

    await tester.tap(tab(0));
    await tester.pumpAndSettle();
    expect(repository.reads, 2);
  });

  testWidgets('someone opening the app, and every minute, reads again', (
    tester,
  ) async {
    final presence = _FakeAppPresence();
    getIt.registerSingleton<AppPresence>(presence);
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
    expect(repository.reads, 1);

    // A client opens the app: the numbers are read a moment later.
    presence.online.value = {'admin-1', 'client-1'};
    await tester.pump(AdminDashboardTab.presenceSettle);
    await tester.pumpAndSettle();
    expect(repository.reads, 2);

    await tester.pump(AdminDashboardTab.refreshEvery);
    await tester.pumpAndSettle();
    expect(repository.reads, 3);

    // Hidden behind another tab, it waits.
    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBottomNav),
            matching: find.byType(InkWell),
          )
          .at(1),
    );
    await tester.pumpAndSettle();
    presence.online.value = {'admin-1'};
    await tester.pump(AdminDashboardTab.refreshEvery);
    await tester.pumpAndSettle();
    expect(repository.reads, 3);
  });

  testWidgets('a pending count opens the «التوثيق» tab', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('رخص بانتظار التوثيق'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminReviewPage), findsOneWidget);
  });

  testWidgets('the open tickets open the «البلاغات» tab; back reads again', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
    expect(find.text('٥'), findsOneWidget);
    final reads = repository.reads;

    await tester.tap(find.text('بلاغات مفتوحة'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminReportsPage), findsOneWidget);
    // A tab: no back arrow.
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBottomNav),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(repository.reads, reads + 1);
  });

  testWidgets('the blockchain card says what needs attention and opens the '
      '«البلوك تشين» tab', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('admin_dashboard_blockchain'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    // One project needs a person; that comes before the two waiting.
    expect(
      find.descendant(of: card, matching: find.text('١ يحتاج مراجعة')),
      findsOneWidget,
    );

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(AdminBlockchainPage), findsOneWidget);
  });

  testWidgets('the blockchain card reads «متزامن» when nothing waits', (
    tester,
  ) async {
    repository.statsResult = const Success(
      AdminDashboardStats(
        activeUsers: 1,
        clients: 1,
        businesses: 1,
        verifiedBusinesses: 1,
        projects: 1,
        draftProjects: 0,
        openProjects: 0,
        inProgressProjects: 1,
        completedProjects: 0,
        cancelledProjects: 0,
        marketItems: 0,
        liveMarketItems: 0,
        pendingLicenses: 0,
        pendingDeeds: 0,
        openReports: 0,
        onlineUsers: 0,
        blockchainFailed: 0,
        blockchainPending: 0,
      ),
    );
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('admin_dashboard_blockchain')),
        matching: find.text('متزامن'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every management button is open, none says «قريباً»', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    // The «الرئيسية» tab, which connects the buttons.
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('إدارة منتجات السوق'));
    await tester.pumpAndSettle();
    expect(find.text('إدارة المستخدمين'), findsOneWidget);
    expect(find.text('قريباً'), findsNothing);
  });

  testWidgets('a failed read offers to try again', (tester) async {
    repository.statsResult = const Failed(NetworkFailure());
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    repository.statsResult = const Success(fakeAdminDashboardStats);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('رخص بانتظار التوثيق'), findsOneWidget);
  });

  testWidgets('fits large bold text, on every chip', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: largeTextScale,
      boldText: true,
    );
    router.goNamed(AdminDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final chip in ['المستخدمون', 'المشاريع', 'السوق']) {
      await tester.ensureVisible(find.text(chip).first);
      await tester.tap(find.text(chip).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: chip);
    }
  });
}

/// The app's presence, with [online] set by the test.
class _FakeAppPresence implements AppPresence {
  final ValueNotifier<Set<String>> online = ValueNotifier({'admin-1'});

  @override
  ValueListenable<Set<String>> get onlineUserIds => online;

  @override
  void start() {}

  @override
  Future<void> stop() async {}
}
