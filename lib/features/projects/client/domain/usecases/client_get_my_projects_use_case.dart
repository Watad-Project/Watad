import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// The client's projects, newest first.
class ClientGetMyProjectsUseCase
    implements UseCase<List<ClientProject>, NoParams> {
  const ClientGetMyProjectsUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<List<ClientProject>>> call(NoParams params) =>
      _repository.getMyProjects();
}
