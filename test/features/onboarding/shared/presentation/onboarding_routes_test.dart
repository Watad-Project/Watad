import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/onboarding_routes.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_onboarding_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    registerFakeOnboardingBloc();
    registerFakeAuthBloc(FakeAuthRepository());
    // The router opens at the splash page first (appStartPath). Its fake
    // never answers, so it stays there.
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(getIt.reset);

  // Not pumpAndSettle: the slide animation loops.
  Future<void> pumpOneSecond(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('every onboarding route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(OnboardingRoutes.onboardingName);
    await pumpOneSecond(tester);
    expect(currentPath(router), OnboardingRoutes.onboardingPath);
    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('finishing the onboarding goes to the login page', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(OnboardingRoutes.onboardingName);
    await pumpOneSecond(tester);
    await tester.tap(find.text('تخطّي'));
    await pumpOneSecond(tester);
    expect(currentPath(router), AuthRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
