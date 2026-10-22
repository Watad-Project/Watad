import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_dashboard_routes.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/dashboard/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_page.dart';

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
    // Arabic-Indic digits with separators.
    expect(find.text('١٬٢٤٠'), findsOneWidget);
    expect(find.text('٢١٢ موثّقة'), findsOneWidget);
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

  testWidgets('the open tickets open «البلاغات», and back reads again', (
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

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(repository.reads, reads + 1);
  });

  testWidgets('the management buttons wait for their screens', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('إدارة منتجات السوق'), 200);
    expect(find.text('قريباً'), findsNWidgets(2));
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
    expect(find.text('١٬٢٤٠'), findsOneWidget);
  });

  testWidgets('fits large bold text', (tester) async {
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
  });
}
