import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';

import '../../helpers/fake_app_session.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_splash_repository.dart';
import '../../helpers/pump_router.dart';

/// A session whose role can't be read, e.g. offline.
class _UnreadableRoleSession extends FakeAppSession {
  @override
  Future<AppRole> role() async => throw Exception('offline');
}

// Each role folder tests its own routes in
// test/features/<feature>/<role>/presentation/ (APP_ARCHITECTURE.md §11).
void main() {
  setUp(() {
    // The splash fake never answers, so the app stays at its start path.
    registerFakeSplashBloc(FakeSplashRepository());
    registerFakeAuthBloc(FakeAuthRepository());
  });

  tearDown(getIt.reset);

  testWidgets('starts at the start path', (tester) async {
    final router = await pumpAppRouter(tester);

    expect(currentPath(router), appStartPath);
  });

  testWidgets('an unknown address shows the not-found page', (tester) async {
    final router = await pumpAppRouter(tester);

    router.go('/no-such-page');
    await tester.pumpAndSettle();
    expect(find.byType(AppNotFoundView), findsOneWidget);

    await tester.tap(find.text('العودة إلى البداية'));
    await tester.pumpAndSettle();
    expect(currentPath(router), appStartPath);
  });

  group('the guard', () {
    const navigationOf = {
      AppRole.client: ClientNavigationRoutes.navigationPath,
      AppRole.contractor: ContractorNavigationRoutes.navigationPath,
      AppRole.admin: AdminNavigationRoutes.navigationPath,
    };

    for (final MapEntry(key: role, value: path) in navigationOf.entries) {
      testWidgets('signing in on the login page opens the ${role.name} '
          'navigation', (tester) async {
        final session = FakeAppSession();
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: AuthRoutes.loginPath,
        );
        expect(currentPath(router), AuthRoutes.loginPath);

        // What the login page's verified code does to the session.
        session.signIn(role);
        await tester.pumpAndSettle();
        expect(currentPath(router), path);
        expect(router.canPop(), isFalse);
      });
    }

    testWidgets('a signed-in user who opens the login page goes on to their '
        'navigation', (tester) async {
      final router = await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.contractor),
      );

      router.goNamed(AuthRoutes.loginName);
      await tester.pumpAndSettle();
      expect(currentPath(router), ContractorNavigationRoutes.navigationPath);
    });

    testWidgets('signed out, a navigation sends to the login page', (
      tester,
    ) async {
      final router = await pumpAppRouter(tester);

      router.goNamed(ClientNavigationRoutes.navigationName);
      await tester.pumpAndSettle();
      expect(currentPath(router), AuthRoutes.loginPath);
    });

    testWidgets("a role can't open another role's navigation", (tester) async {
      final router = await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.client),
      );

      router.goNamed(AdminNavigationRoutes.navigationName);
      await tester.pumpAndSettle();
      expect(currentPath(router), ClientNavigationRoutes.navigationPath);
    });

    testWidgets('signing out on a navigation goes to the login page', (
      tester,
    ) async {
      final session = FakeAppSession()..signIn(AppRole.admin);
      final router = await pumpAppRouter(
        tester,
        session: session,
        initialLocation: AdminNavigationRoutes.navigationPath,
      );
      expect(currentPath(router), AdminNavigationRoutes.navigationPath);

      session.signOut();
      await tester.pumpAndSettle();
      expect(currentPath(router), AuthRoutes.loginPath);
    });

    testWidgets("when the role can't be read, the user stays on the login "
        'page', (tester) async {
      final session = _UnreadableRoleSession();
      final router = await pumpAppRouter(
        tester,
        session: session,
        initialLocation: AuthRoutes.loginPath,
      );

      session.signIn(AppRole.client);
      await tester.pumpAndSettle();
      expect(currentPath(router), AuthRoutes.loginPath);
    });
  });
}
