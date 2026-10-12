import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';

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
  test('emits SaveInProgress then SaveSuccess on success', () async {
    final bloc = OnboardingBloc(
      MarkOnboardingSeenUseCase(
        FakeOnboardingRepository(const Success<void>(null)),
      ),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingSaveInProgress>(),
        isA<OnboardingSaveSuccess>(),
      ]),
    );

    bloc.add(const OnboardingFinished());
    await states;
    await bloc.close();
  });

  test('emits SaveInProgress then SaveFailure on failure', () async {
    final bloc = OnboardingBloc(
      MarkOnboardingSeenUseCase(
        FakeOnboardingRepository(const Failed<void>(UnknownFailure())),
      ),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingSaveInProgress>(),
        isA<OnboardingSaveFailure>().having(
          (state) => state.failure,
          'failure',
          isA<UnknownFailure>(),
        ),
      ]),
    );

    bloc.add(const OnboardingFinished());
    await states;
    await bloc.close();
  });

  test('saves once when finished twice', () async {
    final repository = FakeOnboardingRepository(const Success<void>(null));
    final bloc = OnboardingBloc(MarkOnboardingSeenUseCase(repository));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingSaveInProgress>(),
        isA<OnboardingSaveSuccess>(),
      ]),
    );

    bloc
      ..add(const OnboardingFinished())
      ..add(const OnboardingFinished());
    await states;
    await bloc.close();

    expect(repository.calls, 1);
  });
}
