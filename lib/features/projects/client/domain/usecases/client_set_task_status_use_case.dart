import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_status_params.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// Accepts or rejects a task the contractor proposed. The client answers
/// only `accepted` or `rejected` here; the server checks the task is still
/// proposed and the project in progress.
class ClientSetTaskStatusUseCase
    implements UseCase<void, ClientTaskStatusParams> {
  const ClientSetTaskStatusUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(ClientTaskStatusParams params) async {
    if (params.status != TaskStatus.accepted &&
        params.status != TaskStatus.rejected) {
      return const Failed(ValidationFailure('validation.invalid'));
    }
    return _repository.setTaskStatus(params);
  }
}
