import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update_rejection.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// Rejects a pending update (GRA-51): the task goes back to the contractor,
/// who fixes the work and sends a new update. The reason (at most 200
/// characters, as the server allows) and the details (at most 1000) are
/// both required; they're sent trimmed.
class ClientRejectTaskUpdateUseCase
    implements UseCase<void, ClientTaskUpdateRejection> {
  const ClientRejectTaskUpdateUseCase(this._repository);

  final ClientProjectsRepository _repository;

  static const int _maxReasonLength = 200;
  static const int _maxDetailsLength = 1000;

  @override
  Future<Result<void>> call(ClientTaskUpdateRejection params) async {
    final reason = params.reason.trim();
    final details = params.details.trim();
    if (reason.isEmpty || reason.length > _maxReasonLength) {
      return const Failed(ValidationFailure('validation.invalid'));
    }
    if (details.isEmpty) {
      return const Failed(ValidationFailure('common.reason_required'));
    }
    if (details.length > _maxDetailsLength) {
      return const Failed(
        ValidationFailure('projects.client.reject_details_too_long'),
      );
    }
    return _repository.rejectTaskUpdate(
      ClientTaskUpdateRejection(
        updateId: params.updateId,
        reason: reason,
        details: details,
      ),
    );
  }
}
