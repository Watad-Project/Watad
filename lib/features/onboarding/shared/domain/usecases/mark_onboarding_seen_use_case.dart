import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';

/// The user skipped or finished the onboarding: never show it again.
class MarkOnboardingSeenUseCase implements UseCase<void, NoParams> {
  const MarkOnboardingSeenUseCase(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) =>
      _repository.markOnboardingSeen();
}
