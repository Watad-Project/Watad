import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
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
}
