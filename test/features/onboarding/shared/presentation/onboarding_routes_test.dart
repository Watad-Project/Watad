import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/onboarding_routes.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  const FakeOnboardingRepository();

  @override
  Future<Result<void>> markOnboardingSeen() async => const Success<void>(null);
}

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository();

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      const Success(SplashDestination.login);
}

void main() {
  testWidgets('every onboarding route opens its page at its path', (
    tester,
  ) async {
    getIt
      ..registerFactory(
        () => OnboardingBloc(
          const MarkOnboardingSeenUseCase(FakeOnboardingRepository()),
        ),
      )
      // The router opens at the splash page first (appStartPath).
      ..registerFactory(
        () => SplashBloc(
          const GetInitialDestinationUseCase(FakeSplashRepository()),
        ),
      );
    addTearDown(getIt.reset);

    final router = await pumpAppRouter(tester);

    router.goNamed(OnboardingRoutes.onboardingName);
    // Not pumpAndSettle: the slide animation loops.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentPath(router), OnboardingRoutes.onboardingPath);
    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}
