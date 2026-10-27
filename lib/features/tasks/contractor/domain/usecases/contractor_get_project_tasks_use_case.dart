import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

class ContractorGetProjectTasksUseCase
    implements UseCase<List<ContractorProjectTask>, String> {
  const ContractorGetProjectTasksUseCase(this._repository);

  final ContractorTasksRepository _repository;

  @override
  Future<Result<List<ContractorProjectTask>>> call(String projectId) {
    return _repository.getProjectTasks(projectId);
  }
}
