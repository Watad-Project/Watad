import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_new_task.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

class ContractorCreateTaskUseCase implements UseCase<void, ContractorNewTask> {
  const ContractorCreateTaskUseCase(this._repository);

  final ContractorTasksRepository _repository;

  @override
  Future<Result<void>> call(ContractorNewTask task) {
    return _repository.createTask(task);
  }
}
