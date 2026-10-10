/// Why something failed. The page shows `context.tr(failure.messageKey)`;
/// [cause] is the original error, for logs only (APP_ARCHITECTURE.md §13).
///
/// `guardSupabaseCall` turns backend errors into these. Use cases return
/// [ValidationFailure] with their own key when they reject the input.
sealed class Failure {
  const Failure(this.messageKey, [this.cause]);

  /// A translation key, e.g. `errors.network`.
  final String messageKey;

  /// The error behind the failure. Never show it to the user.
  final Object? cause;
}

/// No connection, or the request timed out.
final class NetworkFailure extends Failure {
  const NetworkFailure([Object? cause]) : super('errors.network', cause);
}

/// Not signed in, the session expired, or the code was wrong.
final class AuthFailure extends Failure {
  const AuthFailure([Object? cause]) : super('errors.auth', cause);
}

/// Row-level security or an RPC rejected the caller.
final class PermissionFailure extends Failure {
  const PermissionFailure([Object? cause]) : super('errors.permission', cause);
}

/// The row or file does not exist, or the caller cannot see it.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([Object? cause]) : super('errors.not_found', cause);
}

/// A unique value is taken, or the data changed in the meantime.
final class ConflictFailure extends Failure {
  const ConflictFailure([Object? cause]) : super('errors.conflict', cause);
}

/// Too many attempts in a short time, e.g. asking for sign-in codes.
final class RateLimitFailure extends Failure {
  const RateLimitFailure([Object? cause]) : super('errors.rate_limit', cause);
}

/// The input was rejected, with its own key: `validation.title_required`
/// from a use case, `validation.invalid` from a database check.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.messageKey, [super.cause]);
}

/// Any other database, storage or RPC error.
final class ServerFailure extends Failure {
  const ServerFailure([Object? cause]) : super('errors.server', cause);
}

/// Anything else.
final class UnknownFailure extends Failure {
  const UnknownFailure([Object? cause]) : super('errors.unknown', cause);
}
