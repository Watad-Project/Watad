import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

/// Fetches a single task update by id from `v_project_task_updates` (GRA-39).
class ContractorGetTaskUpdateUseCase
    implements UseCase<ContractorTaskUpdate, String> {
  const ContractorGetTaskUpdateUseCase(this._repository);

  final ContractorTasksRepository _repository;

  @override
  Future<Result<ContractorTaskUpdate>> call(String updateId) =>
      _repository.getTaskUpdate(updateId);
}
