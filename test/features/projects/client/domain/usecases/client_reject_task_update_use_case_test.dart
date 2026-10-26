import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update_rejection.dart';
import 'package:watad/features/projects/client/domain/usecases/client_reject_task_update_use_case.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  late FakeClientProjectsRepository repository;

  Future<Result<void>> reject({
    required String reason,
    required String details,
  }) => ClientRejectTaskUpdateUseCase(repository)(
    ClientTaskUpdateRejection(
      updateId: 'u-3',
      reason: reason,
      details: details,
    ),
  );

  String failureKey(Result<void> result) =>
      (result as Failed<void>).failure.messageKey;

  setUp(() => repository = FakeClientProjectsRepository());

  test('sends the reason and the details, trimmed', () async {
    final result = await reject(
      reason: ' الأدلة غير كافية ',
      details: '  لا تظهر زوايا السقف.  ',
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejections, [
      ('u-3', 'الأدلة غير كافية', 'لا تظهر زوايا السقف.'),
    ]);
  });

  test('needs the details', () async {
    final result = await reject(reason: 'أخرى', details: '   ');

    expect(failureKey(result), 'common.reason_required');
    expect(repository.rejections, isEmpty);
  });

  test('takes up to 1000 characters of details, no more', () async {
    expect(
      await reject(reason: 'أخرى', details: 'ت' * 1000),
      isA<Success<void>>(),
    );

    final result = await reject(reason: 'أخرى', details: 'ت' * 1001);
    expect(failureKey(result), 'projects.client.reject_details_too_long');
    expect(repository.rejections, hasLength(1));
  });

  test('needs a reason of at most 200 characters', () async {
    expect(
      failureKey(await reject(reason: ' ', details: 'تفاصيل')),
      'validation.invalid',
    );
    expect(
      failureKey(await reject(reason: 'س' * 201, details: 'تفاصيل')),
      'validation.invalid',
    );
    expect(repository.rejections, isEmpty);
  });

  test('passes the server\'s refusal on', () async {
    repository.rejectTaskUpdateResult = const Failed(ConflictFailure());

    final result = await reject(reason: 'أخرى', details: 'تفاصيل');

    expect((result as Failed<void>).failure, isA<ConflictFailure>());
  });
}
