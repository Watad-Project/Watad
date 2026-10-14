part of 'onboarding_bloc.dart';

sealed class OnboardingEvent {
  const OnboardingEvent();
}

/// The user tapped skip, or the button on the last slide.
final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}
