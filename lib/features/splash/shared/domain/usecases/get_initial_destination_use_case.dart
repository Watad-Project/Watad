import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';

class GetInitialDestinationUseCase
    implements UseCase<SplashDestination, NoParams> {
  const GetInitialDestinationUseCase(this._repository);

  final SplashRepository _repository;

  @override
  Future<Result<SplashDestination>> call(NoParams params) =>
      _repository.determineInitialDestination();
}
