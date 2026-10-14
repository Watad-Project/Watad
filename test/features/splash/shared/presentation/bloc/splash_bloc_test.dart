import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

class FakeSplashRepository implements SplashRepository {
  FakeSplashRepository(this.result);

  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

SplashBloc buildBloc(
  Result<SplashDestination> result, {
  Duration minimumDuration = Duration.zero,
}) => SplashBloc(
  GetInitialDestinationUseCase(FakeSplashRepository(result)),
  minimumDuration: minimumDuration,
);

void main() {
  test('emits LoadInProgress then LoadSuccess on success', () async {
    final bloc = buildBloc(const Success(SplashDestination.onboarding));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SplashLoadInProgress>(),
        isA<SplashLoadSuccess>().having(
          (s) => s.destination,
          'destination',
          SplashDestination.onboarding,
        ),
      ]),
    );

    bloc.add(const SplashStarted());
    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure on failure', () async {
    final bloc = buildBloc(const Failed(NetworkFailure()));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<SplashLoadInProgress>(), isA<SplashLoadFailure>()]),
    );

    bloc.add(const SplashStarted());
    await states;
    await bloc.close();
  });

  test('answers only after the minimum duration', () async {
    final bloc = buildBloc(
      const Success(SplashDestination.login),
      minimumDuration: const Duration(milliseconds: 300),
    );

    bloc.add(const SplashStarted());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state, isA<SplashLoadInProgress>());

    await expectLater(bloc.stream, emits(isA<SplashLoadSuccess>()));
    await bloc.close();
  });
}
