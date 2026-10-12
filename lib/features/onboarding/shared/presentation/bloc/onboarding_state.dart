part of 'onboarding_bloc.dart';

sealed class OnboardingState {
  const OnboardingState();
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingSaveInProgress extends OnboardingState {
  const OnboardingSaveInProgress();
}

/// The onboarding is marked as seen: leave it.
final class OnboardingSaveSuccess extends OnboardingState {
  const OnboardingSaveSuccess();
}

final class OnboardingSaveFailure extends OnboardingState {
  const OnboardingSaveFailure(this.failure);

  final Failure failure;
}
