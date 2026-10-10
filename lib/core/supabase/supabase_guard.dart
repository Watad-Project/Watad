import 'dart:async';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';

/// Runs one Supabase call and returns [Success] with its data, or [Failed]
/// with the [Failure] for its error. Every repository method wraps its data
/// source call in it, so nothing throws up to the UI (APP_ARCHITECTURE.md
/// §13).
///
/// ```dart
/// Future<Result<List<ClientProject>>> getMyProjects() =>
///     guardSupabaseCall(_remote.getMyProjects);
/// ```
Future<Result<T>> guardSupabaseCall<T>(Future<T> Function() call) async {
  try {
    return Success(await call());
  } catch (error, stackTrace) {
    return Failed(_failureOf(error, stackTrace));
  }
}

/// [guardSupabaseCall] for realtime: every event of [stream] becomes a
/// [Success], and an error becomes a [Failed] event instead of breaking the
/// listener.
///
/// ```dart
/// Stream<Result<List<ChatMessage>>> watchMessages(String chatId) =>
///     guardSupabaseStream(_remote.watchMessages(chatId));
/// ```
Stream<Result<T>> guardSupabaseStream<T>(Stream<T> stream) {
  return stream.transform(
    StreamTransformer<T, Result<T>>.fromHandlers(
      handleData: (data, sink) => sink.add(Success(data)),
      handleError: (error, stackTrace, sink) =>
          sink.add(Failed(_failureOf(error, stackTrace))),
    ),
  );
}

/// The only place that turns a backend error into a [Failure]
/// (APP_ARCHITECTURE.md §13). The error is logged; the user sees only the
/// failure's message.
Failure _failureOf(Object error, StackTrace stackTrace) {
  log(
    'Supabase call failed',
    name: 'watad.supabase',
    error: error,
    stackTrace: stackTrace,
  );
  return switch (error) {
    PostgrestException(:final code) => _postgrestFailure(code, error),
    AuthRetryableFetchException() => NetworkFailure(error),
    AuthException(statusCode: '429') => RateLimitFailure(error),
    AuthException() => AuthFailure(error),
    StorageException(:final statusCode) => _storageFailure(statusCode, error),
    TimeoutException() => NetworkFailure(error),
    _ when _isConnectionError(error) => NetworkFailure(error),
    _ => UnknownFailure(error),
  };
}

/// [code] is a Postgres SQLSTATE, a PostgREST code, or an HTTP status when
/// the response had no JSON body.
///
/// The RPCs raise their own rules as P0001 with an English message, which
/// lands in [ServerFailure]. The codes below are what they should raise
/// instead (APP_ARCHITECTURE.md §13).
Failure _postgrestFailure(String? code, PostgrestException error) {
  return switch (code) {
    // Row-level security, a missing column grant, or an RPC refusing the
    // caller.
    '42501' || '403' => PermissionFailure(error),
    // The session's token is missing, invalid or expired.
    'PGRST301' || 'PGRST302' || 'PGRST303' || '401' => AuthFailure(error),
    // .single() found no row, or an RPC found nothing (no_data_found).
    'PGRST116' || 'P0002' || '404' => NotFoundFailure(error),
    // A unique value is taken, or the data changed in the meantime.
    '23505' || '40001' || '409' => ConflictFailure(error),
    // A check, not-null or type rule of the database rejected the input.
    '23514' ||
    '23502' ||
    '22P02' ||
    '22023' => ValidationFailure('validation.invalid', error),
    '429' => RateLimitFailure(error),
    _ => ServerFailure(error),
  };
}

Failure _storageFailure(String? statusCode, StorageException error) {
  return switch (statusCode) {
    '401' => AuthFailure(error),
    '403' => PermissionFailure(error),
    '404' => NotFoundFailure(error),
    '409' => ConflictFailure(error),
    '429' => RateLimitFailure(error),
    _ => ServerFailure(error),
  };
}

/// No connection. The database, storage and functions clients send through
/// package:http, which throws its `ClientException` (on mobile it is also a
/// `SocketException`). The app may not depend on package:http
/// (APP_PACKAGES.md), so the exception is recognised by its message, which
/// always starts with its name.
bool _isConnectionError(Object error) =>
    error.toString().startsWith('ClientException');
