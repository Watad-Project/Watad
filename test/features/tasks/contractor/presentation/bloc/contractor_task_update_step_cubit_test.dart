import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';

void main() {
  final tasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'بناء الجدران والهيكل',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 10),
    ),
    ContractorProjectTask(
      id: 't-2',
      projectId: 'p-1',
      title: 'تمديد الكهرباء والسباكة',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 15),
    ),
  ];

  final photo = ContractorTaskEvidencePhoto(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'evidence.jpg',
  );

  test('syncs first task, advances to step 2, and returns to step 1 keeping choice', () async {
    final cubit = ContractorTaskUpdateStepCubit()..syncTasks(tasks);
    expect(cubit.state.selectedTaskId, 't-1');
    expect(cubit.state.step, ContractorTaskUpdateStep.chooseTask);

    cubit.selectTask('t-2');
    expect(cubit.state.selectedTaskId, 't-2');

    cubit.proceedToStepTwo();
    expect(cubit.state.step, ContractorTaskUpdateStep.stateAndEvidence);

    cubit.backToStepOne();
    expect(cubit.state.step, ContractorTaskUpdateStep.chooseTask);
    expect(cubit.state.selectedTaskId, 't-2');

    await cubit.close();
  });

  test('manages proposedState, up to 3 photos, and note', () async {
    final cubit = ContractorTaskUpdateStepCubit(initialTaskId: 't-1')
      ..setProposedState(TaskUpdateState.done)
      ..addPhoto(photo)
      ..addPhoto(photo)
      ..addPhoto(photo)
      ..addPhoto(photo) // ignored (max 3)
      ..setNote('اكتملت أعمال البناء');

    expect(cubit.state.proposedState, TaskUpdateState.done);
    expect(cubit.state.photos, hasLength(3));
    expect(cubit.state.canAddPhoto, isFalse);
    expect(cubit.state.note, 'اكتملت أعمال البناء');

    cubit.removePhotoAt(1);
    expect(cubit.state.photos, hasLength(2));
    expect(cubit.state.canAddPhoto, isTrue);

    await cubit.close();
  });
}
