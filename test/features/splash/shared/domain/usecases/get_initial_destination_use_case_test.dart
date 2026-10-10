import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository(this.result);

  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

void main() {
  test('returns the destination from repository', () async {
    const repository = FakeSplashRepository(
      Success(SplashDestination.onboarding),
    );
    const useCase = GetInitialDestinationUseCase(repository);

    final result = await useCase(const NoParams());

    expect(result, isA<Success<SplashDestination>>());
    expect(
      (result as Success<SplashDestination>).data,
      SplashDestination.onboarding,
    );
  });
}
