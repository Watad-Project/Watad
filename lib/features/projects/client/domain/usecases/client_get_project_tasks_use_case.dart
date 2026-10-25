import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// The tasks of one of the client's projects, in timeline order; the
/// parameter is the project's id.
class ClientGetProjectTasksUseCase
    implements UseCase<List<ClientProjectTask>, String> {
  const ClientGetProjectTasksUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<List<ClientProjectTask>>> call(String params) =>
      _repository.getProjectTasks(params);
}
