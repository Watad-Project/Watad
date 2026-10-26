import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

class ContractorGetTaskProjectUseCase
    implements UseCase<ContractorTaskProject, String> {
  const ContractorGetTaskProjectUseCase(this._repository);

  final ContractorTasksRepository _repository;

  @override
  Future<Result<ContractorTaskProject>> call(String projectId) {
    return _repository.getProject(projectId);
  }
}
