import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';

/// A hand-written [OnboardingRepository] that always saves
/// (APP_ARCHITECTURE.md §16).
class FakeOnboardingRepository implements OnboardingRepository {
  const FakeOnboardingRepository();

  @override
  Future<Result<void>> markOnboardingSeen() async => const Success<void>(null);
}

/// For tests that open the onboarding route: the route builder takes its
/// [OnboardingBloc] from getIt (APP_ARCHITECTURE.md §12). Reset getIt after
/// the test.
void registerFakeOnboardingBloc() {
  getIt.registerFactory(
    () => OnboardingBloc(
      const MarkOnboardingSeenUseCase(FakeOnboardingRepository()),
    ),
  );
}
