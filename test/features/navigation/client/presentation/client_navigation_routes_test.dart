import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/navigation/client/presentation/pages/client_navigation_page.dart';
import 'package:watad/features/navigation/shared/presentation/widgets/navigation_placeholder.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_home_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    // The client's navigation opens on its «الرئيسية» tab.
    registerFakeClientHome();
    // A tab's feature adds its register…Dependencies(getIt) call here when
    // it sets its tab's routeName (ClientNavigationPage.tabs).
    //
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(getIt.reset);

  testWidgets('every client navigation route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );

    router.goNamed(ClientNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
    expect(currentPath(router), ClientNavigationRoutes.navigationPath);
    expect(find.byType(ClientNavigationPage), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('every tab opens its screen or, until then, a placeholder', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientNavigationRoutes.navigationName);
    await tester.pumpAndSettle();

    const tabs = ClientNavigationPage.tabs;
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
