import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

class FakeContractorTasksRepository implements ContractorTasksRepository {
  Result<ContractorTaskProject> projectResult = Success(
    ContractorTaskProject(
      id: 'proj-1',
      title: 'فيلا سكنية',
      status: ProjectStatus.inProgress,
      ownerName: 'عبدالله الحربي',
      city: 'الرياض',
      district: 'حي الياسمين',
      agreedAmount: const Money.halalas(48000000),
      totalPaid: const Money.halalas(9000000),
      totalScheduled: const Money.halalas(21000000),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );

  Result<List<ContractorProjectTask>> tasksResult = const Success([]);

  @override
  Future<Result<ContractorTaskProject>> getProject(String projectId) async =>
      projectResult;

  @override
  Future<Result<List<ContractorProjectTask>>> getProjectTasks(
    String projectId,
  ) async => tasksResult;
}
