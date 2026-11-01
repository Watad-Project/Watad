import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';

abstract interface class ContractorTasksRepository {
  Future<Result<ContractorTaskProject>> getProject(String projectId);

  Future<Result<List<ContractorProjectTask>>> getProjectTasks(String projectId);

  Future<Result<String>> submitTaskUpdate(
    ContractorSubmitTaskUpdateParams params,
  );

  Future<Result<ContractorTaskUpdate>> getTaskUpdate(String updateId);

  Stream<Result<ContractorTaskUpdate>> watchTaskUpdate(String updateId);
}
