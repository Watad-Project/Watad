import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientCreateProjectUseCase implements UseCase<void, ClientNewProject> {
  const ClientCreateProjectUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(ClientNewProject params) async {
    if (params.title.trim().isEmpty) {
      return const Failed(ValidationFailure('validation.title_required'));
    }
    if (params.city.trim().isEmpty) {
      return const Failed(ValidationFailure('validation.city_required'));
    }
    return _repository.createProject(params);
  }
}
