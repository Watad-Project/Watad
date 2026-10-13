import 'package:watad/core/error/result.dart';

/// Remembers on the phone that the user has seen the onboarding, so it is
/// shown only once.
abstract interface class OnboardingRepository {
  Future<Result<void>> markOnboardingSeen();
}
