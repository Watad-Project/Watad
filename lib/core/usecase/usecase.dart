import 'package:watad/core/error/result.dart';

/// One action of the app. Blocs call use cases; use cases call repositories.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// For use cases that need no input.
final class NoParams {
  const NoParams();
}
