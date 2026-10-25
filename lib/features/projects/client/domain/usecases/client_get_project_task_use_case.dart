import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// One task of the client's projects; the parameter is its id.
class ClientGetProjectTaskUseCase
    implements UseCase<ClientProjectTask, String> {
  const ClientGetProjectTaskUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<ClientProjectTask>> call(String params) =>
      _repository.getProjectTask(params);
}
