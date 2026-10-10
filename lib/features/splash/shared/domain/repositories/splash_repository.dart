import 'package:watad/core/error/result.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';

abstract interface class SplashRepository {
  Future<Result<SplashDestination>> determineInitialDestination();
}
