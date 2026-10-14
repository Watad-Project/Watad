import 'dart:async';

import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

/// A hand-written [SplashRepository] (APP_ARCHITECTURE.md §16). It answers
/// only once the test calls [answer], so until then the splash page stays on
/// screen instead of leaving for the next route.
class FakeSplashRepository implements SplashRepository {
  // Created on first use, inside the test body: a widget test's fake clock
  // only runs futures created there, and setUp runs outside it.
  late final Completer<Result<SplashDestination>> _answer = Completer();

  /// Answers every call, past and future, with [result].
  void answer(Result<SplashDestination> result) => _answer.complete(result);

  @override
  Future<Result<SplashDestination>> determineInitialDestination() =>
      _answer.future;
}

/// For tests that open the splash route, which the router opens first: the
/// route builder takes its [SplashBloc] from getIt (APP_ARCHITECTURE.md §12).
/// Reset getIt after the test.
void registerFakeSplashBloc(FakeSplashRepository repository) {
  getIt.registerFactory(
    () => SplashBloc(GetInitialDestinationUseCase(repository)),
  );
}
