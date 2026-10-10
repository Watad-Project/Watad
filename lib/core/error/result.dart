import 'package:watad/core/error/failure.dart';

/// What a repository returns. Repositories never throw: they return
/// [Success] with the data or [Failed] with a [Failure].
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;
}
