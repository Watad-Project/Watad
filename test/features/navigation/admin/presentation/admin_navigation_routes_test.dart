import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/navigation/admin/presentation/pages/admin_navigation_page.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_placeholder.dart';

import '../../../../helpers/fake_admin_dashboard_repository.dart';
import '../../../../helpers/fake_admin_reports_repository.dart';
import '../../../../helpers/fake_admin_review_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    // A tab's feature adds its register…Dependencies(getIt) call here when
    // it sets its tab's routeName (AdminNavigationPage.tabs).
    registerFakeAdminDashboard(FakeAdminDashboardRepository());
    registerFakeAdminReports(FakeAdminReportsRepository());
    registerFakeAdminReview(FakeAdminReviewRepository());
    //
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(getIt.reset);

  testWidgets('every admin navigation route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );

    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AdminNavigationRoutes.navigationPath);
    expect(find.byType(AdminNavigationPage), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('every tab opens its screen or, until then, a placeholder', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();

    const tabs = AdminNavigationPage.tabs;
    for (final (index, tab) in tabs.indexed) {
      await tester.tap(
        find
            .descendant(
              of: find.byType(AppBottomNav),
              matching: find.byType(InkWell),
            )
            .at(index),
      );
      await tester.pumpAndSettle();
      if (tab.routeName == null) {
        expect(find.byType(NavigationPlaceholder), findsOneWidget);
      }
    }
    expect(tester.takeException(), isNull);
  });
}
