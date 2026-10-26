import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/tasks/contractor/datasource/remote/contractor_tasks_remote_data_source.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

class ContractorTasksRepositoryImpl implements ContractorTasksRepository {
  const ContractorTasksRepositoryImpl(this._remote);

  final ContractorTasksRemoteDataSource _remote;

  @override
  Future<Result<ContractorTaskProject>> getProject(String projectId) {
    return guardSupabaseCall(() => _remote.getProject(projectId));
  }

  @override
  Future<Result<List<ContractorProjectTask>>> getProjectTasks(
    String projectId,
  ) {
    return guardSupabaseCall(() => _remote.getProjectTasks(projectId));
  }
}
