import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientGetProjectByIdUseCase implements UseCase<ClientProject, String> {
  const ClientGetProjectByIdUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<ClientProject>> call(String params) =>
      _repository.getProjectById(params);
}
