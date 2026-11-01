import 'dart:async';

import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
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

  Result<String> submitUpdateResult = const Success('upd-new-1');

  Result<ContractorTaskUpdate> taskUpdateResult = Success(
    ContractorTaskUpdate(
      id: 'upd-1',
      taskId: 't-1',
      taskTitle: 'اللياسة الداخلية',
      projectId: 'p-1',
      projectTitle: 'فيلا سكنية',
      projectDistrict: 'حي الياسمين',
      proposedState: TaskUpdateState.done,
      decision: TaskUpdateDecision.pending,
      taskAmount: const Money.halalas(2400000),
      createdAt: DateTime.utc(2026, 10, 28, 6, 40),
    ),
  );

  final List<ContractorSubmitTaskUpdateParams> submittedUpdates = [];

  final StreamController<Result<ContractorTaskUpdate>> _updateController =
      StreamController<Result<ContractorTaskUpdate>>.broadcast();

  void emitLiveUpdate(Result<ContractorTaskUpdate> result) {
    _updateController.add(result);
  }

  Future<void> dispose() => _updateController.close();

  @override
  Future<Result<ContractorTaskProject>> getProject(String projectId) async =>
      projectResult;

  @override
  Future<Result<List<ContractorProjectTask>>> getProjectTasks(
    String projectId,
  ) async => tasksResult;

  @override
  Future<Result<String>> submitTaskUpdate(
    ContractorSubmitTaskUpdateParams params,
  ) async {
    submittedUpdates.add(params);
    return submitUpdateResult;
  }

  @override
  Future<Result<ContractorTaskUpdate>> getTaskUpdate(String updateId) async =>
      taskUpdateResult;

  @override
  Stream<Result<ContractorTaskUpdate>> watchTaskUpdate(String updateId) =>
      _updateController.stream;
}
