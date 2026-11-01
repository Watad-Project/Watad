import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_submit_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';

import '../../../../../helpers/fake_contractor_tasks_repository.dart';

void main() {
  late FakeContractorTasksRepository repository;

  final allTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-open-1',
      projectId: 'p-1',
      title: 'بناء الجدران والهيكل',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 10),
    ),
    ContractorProjectTask(
      id: 't-pending-update',
      projectId: 'p-1',
      title: 'العزل المائي',
      status: TaskStatus.accepted,
      hasPendingUpdate: true,
      createdAt: DateTime.utc(2026, 1, 12),
    ),
    ContractorProjectTask(
      id: 't-done',
      projectId: 'p-1',
      title: 'صب الأساسات',
      status: TaskStatus.done,
      createdAt: DateTime.utc(2026, 1, 5),
    ),
    ContractorProjectTask(
      id: 't-open-2',
      projectId: 'p-1',
      title: 'تمديد الكهرباء والسباكة',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 15),
    ),
  ];

  ContractorTaskUpdateBloc buildBloc() => ContractorTaskUpdateBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
    ContractorSubmitTaskUpdateUseCase(repository),
  );

  setUp(() {
    repository = FakeContractorTasksRepository()
      ..tasksResult = Success(allTasks);
  });

  test('loads only tasks open for a progress update (canSendUpdate)', () async {
    final bloc = buildBloc()..add(const ContractorTaskUpdateFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ContractorTaskUpdateStatus.success,
    );

    expect(state.tasks.map((t) => t.id), ['t-open-1', 't-open-2']);
    await bloc.close();
  });

  test('emits failure when fetching tasks fails', () async {
    repository.tasksResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ContractorTaskUpdateFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ContractorTaskUpdateStatus.failure,
    );

    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('submits task update and emits submittedUpdateId on success', () async {
    final bloc = buildBloc();
    bloc.add(
      ContractorTaskUpdateSubmitted(
        ContractorSubmitTaskUpdateParams(
          taskId: 't-open-1',
          proposedState: TaskUpdateState.done,
          photos: [
            ContractorTaskEvidencePhoto(
              bytes: Uint8List.fromList([1, 2, 3]),
              fileName: 'photo.jpg',
            ),
          ],
          note: 'تم إنجاز المرحلة بالكامل',
        ),
      ),
    );

    final state = await bloc.stream.firstWhere(
      (s) => !s.isSubmitting && s.submittedUpdateId != null,
    );

    expect(state.submittedUpdateId, 'upd-new-1');
    expect(repository.submittedUpdates, hasLength(1));
    await bloc.close();
  });

  test('emits submissionFailure when validation fails', () async {
    final bloc = buildBloc();
    bloc.add(
      const ContractorTaskUpdateSubmitted(
        ContractorSubmitTaskUpdateParams(
          taskId: 't-open-1',
          proposedState: TaskUpdateState.done,
        ),
      ),
    );

    final state = await bloc.stream.firstWhere(
      (s) => !s.isSubmitting && s.submissionFailure != null,
    );

    expect(
      state.submissionFailure?.messageKey,
      'tasks.contractor.error_evidence_required',
    );
    await bloc.close();
  });
}
