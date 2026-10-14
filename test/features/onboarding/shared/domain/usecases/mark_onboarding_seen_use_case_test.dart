import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository(this.result);

  final Result<void> result;

  int calls = 0;

  @override
  Future<Result<void>> markOnboardingSeen() async {
    calls++;
    return result;
  }
}

void main() {
  test('marks the onboarding as seen through the repository', () async {
    final repository = FakeOnboardingRepository(const Success<void>(null));
    final useCase = MarkOnboardingSeenUseCase(repository);

    final result = await useCase(const NoParams());

    expect(result, isA<Success<void>>());
    expect(repository.calls, 1);
  });

  test('returns the repository failure', () async {
    final repository = FakeOnboardingRepository(
      const Failed<void>(UnknownFailure()),
    );
    final useCase = MarkOnboardingSeenUseCase(repository);

    final result = await useCase(const NoParams());

    expect(result, isA<Failed<void>>());
  });
}
