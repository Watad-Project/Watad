import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_submit_task_update_use_case.dart';

import '../../../../../helpers/fake_contractor_tasks_repository.dart';

void main() {
  late FakeContractorTasksRepository repository;
  late ContractorSubmitTaskUpdateUseCase useCase;

  final samplePhoto = ContractorTaskEvidencePhoto(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'site.jpg',
  );

  setUp(() {
    repository = FakeContractorTasksRepository();
    useCase = ContractorSubmitTaskUpdateUseCase(repository);
  });

  test(
    'submits in_progress update without photos and normalizes blank note',
    () async {
      final result = await useCase(
        const ContractorSubmitTaskUpdateParams(
          taskId: 't-1',
          proposedState: TaskUpdateState.inProgress,
          note: '   ',
        ),
      );

      expect(result, isA<Success<String>>());
      expect(repository.submittedUpdates, hasLength(1));
      expect(repository.submittedUpdates.single.note, isNull);
    },
  );

  test('requires at least one photo when proposedState is done', () async {
    final result = await useCase(
      const ContractorSubmitTaskUpdateParams(
        taskId: 't-1',
        proposedState: TaskUpdateState.done,
      ),
    );

    expect(result, isA<Failed<String>>());
    final failure = (result as Failed<String>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'tasks.contractor.error_evidence_required');
    expect(repository.submittedUpdates, isEmpty);
  });

  test(
    'rejects marking a task done before its start date in Riyadh time',
    () async {
      final result = await useCase(
        ContractorSubmitTaskUpdateParams(
          taskId: 't-1',
          proposedState: TaskUpdateState.done,
          photos: [samplePhoto],
          taskStartDate: DateTime.utc(2026, 5, 10),
          now: DateTime.utc(2026, 5, 9, 12),
        ),
      );

      expect(result, isA<Failed<String>>());
      final failure = (result as Failed<String>).failure;
      expect(failure.messageKey, 'tasks.contractor.error_finish_before_start');
      expect(repository.submittedUpdates, isEmpty);
    },
  );

  test('rejects more than 3 evidence photos', () async {
    final result = await useCase(
      ContractorSubmitTaskUpdateParams(
        taskId: 't-1',
        proposedState: TaskUpdateState.inProgress,
        photos: [samplePhoto, samplePhoto, samplePhoto, samplePhoto],
      ),
    );

    expect(result, isA<Failed<String>>());
    final failure = (result as Failed<String>).failure;
    expect(failure.messageKey, 'tasks.contractor.error_max_photos');
  });

  test('rejects note longer than 5000 characters', () async {
    final result = await useCase(
      ContractorSubmitTaskUpdateParams(
        taskId: 't-1',
        proposedState: TaskUpdateState.inProgress,
        note: 'أ' * 5001,
      ),
    );

    expect(result, isA<Failed<String>>());
    final failure = (result as Failed<String>).failure;
    expect(failure.messageKey, 'tasks.contractor.error_note_too_long');
  });
}
