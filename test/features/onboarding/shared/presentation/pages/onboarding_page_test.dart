import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/onboarding_routes.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';

import '../../../../../helpers/fake_auth_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_component.dart';
import '../../../../../helpers/pump_router.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository([this.result = const Success<void>(null)]);

  final Result<void> result;

  int calls = 0;

  @override
  Future<Result<void>> markOnboardingSeen() async {
    calls++;
    return result;
  }
}

void main() {
  late FakeOnboardingRepository repository;

  // For the tests that don't leave the page: no router needed.
  Future<void> pumpPage(
    WidgetTester tester, {
    Locale locale = AppLocalization.arabic,
  }) async {
    await pumpLocalizedApp(
      tester,
      BlocProvider(
        create: (_) => OnboardingBloc(MarkOnboardingSeenUseCase(repository)),
        child: const OnboardingPage(),
      ),
      locale: locale,
    );
  }

  // Not pumpAndSettle: the slide animation loops.
  Future<void> pumpOneSecond(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // Opens the page in the real router, so finishing can leave it.
  Future<GoRouter> openPage(WidgetTester tester) async {
    getIt.registerFactory(
      () => OnboardingBloc(MarkOnboardingSeenUseCase(repository)),
    );
    registerFakeAuthBloc(FakeAuthRepository());
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    final router = await pumpAppRouter(tester);
    router.goNamed(OnboardingRoutes.onboardingName);
    await pumpOneSecond(tester);
    return router;
  }

  Future<void> tapAndWait(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await pumpOneSecond(tester);
  }

  setUp(() => repository = FakeOnboardingRepository());

  tearDown(getIt.reset);

  testWidgets('starts on the first slide, right to left, with next and skip', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('كل مشروعك في مكان واحد'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(find.text('تخطّي').hitTestable(), findsOneWidget);
    final page = tester.element(find.byType(OnboardingPage));
    expect(Directionality.of(page), TextDirection.rtl);
  });

  testWidgets('next moves to the next slide', (tester) async {
    await pumpPage(tester);

    await tapAndWait(tester, 'التالي');

    expect(find.text('عقود موثّقة لا تتغيّر'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('the last slide says get started, hides skip and finishes', (
    tester,
  ) async {
    final router = await openPage(tester);
    await tapAndWait(tester, 'التالي');
    await tapAndWait(tester, 'التالي');

    expect(find.text('دفعات واضحة على مراحل'), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
    expect(find.text('تخطّي').hitTestable(), findsNothing);

    await tapAndWait(tester, 'ابدأ الآن');

    expect(repository.calls, 1);
    expect(currentPath(router), AuthRoutes.loginPath);
  });

  testWidgets('skip marks the onboarding as seen and finishes', (tester) async {
    final router = await openPage(tester);

    await tapAndWait(tester, 'تخطّي');

    expect(repository.calls, 1);
    expect(currentPath(router), AuthRoutes.loginPath);
  });

  testWidgets('a failed save shows the error and still finishes', (
    tester,
  ) async {
    repository = FakeOnboardingRepository(const Failed<void>(UnknownFailure()));
    final router = await openPage(tester);

    await tapAndWait(tester, 'تخطّي');

    expect(find.text('حدث خطأ ما. حاول مرة أخرى.'), findsOneWidget);
    expect(currentPath(router), AuthRoutes.loginPath);
  });

  testWidgets('shows the English text left to right', (tester) async {
    await pumpPage(tester, locale: AppLocalization.english);

    expect(find.text('Your whole project in one place'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    final page = tester.element(find.byType(OnboardingPage));
    expect(Directionality.of(page), TextDirection.ltr);
  });
}
