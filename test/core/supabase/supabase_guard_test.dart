import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';

/// What package:http throws when there is no connection. The app may not
/// import package:http, so the test copies its message.
class _FakeClientException implements Exception {
  @override
  String toString() => 'ClientException: Failed host lookup';
}

/// The failure that [guardSupabaseCall] returns when the call throws [error].
Future<Failure> _failureFor(Object error) async {
  final result = await guardSupabaseCall<void>(() async => throw error);
  return switch (result) {
    Failed(:final failure) => failure,
    Success() => fail('Expected a failure for $error'),
  };
}

PostgrestException _postgrest(String code) =>
    PostgrestException(message: 'database error', code: code);

void main() {
  test('returns the data as a Success', () async {
    final result = await guardSupabaseCall(() async => 42);

    expect(result, isA<Success<int>>().having((s) => s.data, 'data', 42));
  });

  group('database errors', () {
    final cases = <String, Matcher>{
      '42501': isA<PermissionFailure>(),
      'PGRST303': isA<AuthFailure>(),
      'PGRST116': isA<NotFoundFailure>(),
      'P0002': isA<NotFoundFailure>(),
      '23505': isA<ConflictFailure>(),
      '40001': isA<ConflictFailure>(),
      '23514': isA<ValidationFailure>().having(
        (failure) => failure.messageKey,
        'messageKey',
        'validation.invalid',
      ),
      'P0001': isA<ServerFailure>(),
    };
    for (final MapEntry(key: code, value: matcher) in cases.entries) {
      test(code, () async {
        expect(await _failureFor(_postgrest(code)), matcher);
      });
    }
  });

  test('auth errors', () async {
    expect(
      await _failureFor(const AuthApiException('Token has expired')),
      isA<AuthFailure>(),
    );
    expect(
      await _failureFor(
        const AuthApiException('Too many requests', statusCode: '429'),
      ),
      isA<RateLimitFailure>(),
    );
    expect(
      await _failureFor(AuthRetryableFetchException()),
      isA<NetworkFailure>(),
    );
  });

  test('storage errors', () async {
    expect(
      await _failureFor(
        const StorageException('Object not found', statusCode: '404'),
      ),
      isA<NotFoundFailure>(),
    );
    expect(
      await _failureFor(
        const StorageException('Unauthorized', statusCode: '403'),
      ),
      isA<PermissionFailure>(),
    );
  });

  test('no connection or a timeout is a network failure', () async {
    expect(await _failureFor(_FakeClientException()), isA<NetworkFailure>());
    expect(await _failureFor(TimeoutException('slow')), isA<NetworkFailure>());
  });

  test('anything else is unknown, and keeps its cause', () async {
    final error = StateError('bug');

    expect(
      await _failureFor(error),
      isA<UnknownFailure>().having((f) => f.cause, 'cause', same(error)),
    );
  });

  test('a stream turns events into Success and errors into Failed', () async {
    final controller = StreamController<int>();
    final results = guardSupabaseStream(controller.stream).toList();

    controller
      ..add(1)
      ..addError(_postgrest('42501'))
      ..add(2);
    await controller.close();

    expect(await results, [
      isA<Success<int>>().having((s) => s.data, 'data', 1),
      isA<Failed<int>>().having(
        (f) => f.failure,
        'failure',
        isA<PermissionFailure>(),
      ),
      isA<Success<int>>().having((s) => s.data, 'data', 2),
    ]);
  });
}
