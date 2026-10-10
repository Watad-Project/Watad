/// Failure hierarchy for clean architecture.
sealed class Failure {
  const Failure(this.messageKey, [this.cause]);

  final String messageKey;
  final Object? cause;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([Object? cause]) : super('errors.network', cause);
}

final class AuthFailure extends Failure {
  const AuthFailure([Object? cause]) : super('errors.auth', cause);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([Object? cause]) : super('errors.permission', cause);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([Object? cause]) : super('errors.not_found', cause);
}

final class ConflictFailure extends Failure {
  const ConflictFailure([Object? cause]) : super('errors.conflict', cause);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.messageKey, [super.cause]);
}

final class ServerFailure extends Failure {
  const ServerFailure([Object? cause]) : super('errors.server', cause);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([Object? cause]) : super('errors.unknown', cause);
}
