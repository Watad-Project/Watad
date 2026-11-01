import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_new_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';

abstract interface class ContractorTasksRepository {
  Future<Result<ContractorTaskProject>> getProject(String projectId);

  Future<Result<List<ContractorProjectTask>>> getProjectTasks(String projectId);

  Future<Result<void>> createTask(ContractorNewTask task);
}
