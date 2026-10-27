import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

/// Validates and submits a task progress update (GRA-42) via
/// [ContractorTasksRepository.submitTaskUpdate].
class ContractorSubmitTaskUpdateUseCase
    implements UseCase<String, ContractorSubmitTaskUpdateParams> {
  const ContractorSubmitTaskUpdateUseCase(this._repository);

  final ContractorTasksRepository _repository;

  @override
  Future<Result<String>> call(ContractorSubmitTaskUpdateParams params) async {
    if (params.photos.length > ContractorSubmitTaskUpdateParams.maxPhotos) {
      return const Failed(
        ValidationFailure('tasks.contractor.error_max_photos'),
      );
    }

    final trimmedNote = params.note?.trim();
    if (trimmedNote != null &&
        trimmedNote.length > ContractorSubmitTaskUpdateParams.maxNoteLength) {
      return const Failed(
        ValidationFailure('tasks.contractor.error_note_too_long'),
      );
    }

    if (params.proposedState == TaskUpdateState.done) {
      if (params.photos.isEmpty) {
        return const Failed(
          ValidationFailure('tasks.contractor.error_evidence_required'),
        );
      }

      final startDate = params.taskStartDate;
      if (startDate != null) {
        final riyadhNow = (params.now ?? DateTime.now()).toUtc().add(
          const Duration(hours: 3),
        );
        final riyadhToday = DateTime.utc(
          riyadhNow.year,
          riyadhNow.month,
          riyadhNow.day,
        );
        final normalizedStart = DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        if (normalizedStart.isAfter(riyadhToday)) {
          return const Failed(
            ValidationFailure('tasks.contractor.error_finish_before_start'),
          );
        }
      }
    }

    return _repository.submitTaskUpdate(
      ContractorSubmitTaskUpdateParams(
        taskId: params.taskId,
        proposedState: params.proposedState,
        photos: params.photos,
        note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
        taskStartDate: params.taskStartDate,
        now: params.now,
      ),
    );
  }
}
