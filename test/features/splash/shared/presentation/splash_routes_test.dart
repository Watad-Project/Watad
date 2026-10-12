import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/onboarding_routes.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_onboarding_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeSplashRepository splash;

  setUp(() {
    splash = FakeSplashRepository();
    registerFakeSplashBloc(splash);
    registerFakeOnboardingBloc();
    registerFakeAuthBloc(FakeAuthRepository());
  });

  tearDown(getIt.reset);

  testWidgets('every splash route opens its page at its path', (tester) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(SplashRoutes.splashName);
    await tester.pumpAndSettle();
    expect(currentPath(router), SplashRoutes.splashPath);
    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('goes to the onboarding until it has been seen', (tester) async {
    final router = await pumpAppRouter(tester);

    splash.answer(const Success(SplashDestination.onboarding));
    // Not pumpAndSettle: the slide animation loops.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentPath(router), OnboardingRoutes.onboardingPath);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('goes to the login page once the onboarding is seen', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    splash.answer(const Success(SplashDestination.login));
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('a signed-in user goes to the login page until home exists', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    splash.answer(const Success(SplashDestination.home));
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
