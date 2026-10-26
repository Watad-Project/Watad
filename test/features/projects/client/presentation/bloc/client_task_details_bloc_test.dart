import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_task_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_set_task_status_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_details_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  ClientProject project(ProjectStatus status) => ClientProject(
    id: 'p-3',
    title: 'بناء ملحق',
    status: status,
    city: 'جدة',
    pendingOfferCount: 0,
    createdAt: DateTime.utc(2026, 10, 17),
  );
  ClientProjectTask task(TaskStatus status) => ClientProjectTask(
    id: 't-5',
    title: 'الدهانات',
    description: 'دهان الجدران الداخلية',
    status: status,
  );

  late FakeClientProjectsRepository repository;

  ClientTaskDetailsBloc buildBloc() => ClientTaskDetailsBloc(
    ClientGetProjectUseCase(repository),
    ClientGetProjectTaskUseCase(repository),
    ClientSetTaskStatusUseCase(repository),
  );

  Future<ClientTaskDetailsBloc> loadedBloc() async {
    final bloc = buildBloc()
      ..add(const ClientTaskDetailsFetched(projectId: 'p-3', taskId: 't-5'));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientTaskDetailsStatus.success,
    );
    return bloc;
  }

  setUp(() {
    repository = FakeClientProjectsRepository()
      ..projectResult = Success(project(ProjectStatus.inProgress))
      ..projectTaskResult = Success(task(TaskStatus.proposed));
  });

  test('loads the task: a proposed one can be answered', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.task?.title, 'الدهانات');
    expect(bloc.state.canAnswer, isTrue);
    await bloc.close();
  });

  test('a task that is no longer proposed only reads', () async {
    repository.projectTaskResult = Success(task(TaskStatus.accepted));
    final bloc = await loadedBloc();

    expect(bloc.state.canAnswer, isFalse);
    await bloc.close();
  });

  test('a proposed task waits while the project is not in progress', () async {
    repository.projectResult = Success(project(ProjectStatus.completed));
    final bloc = await loadedBloc();

    expect(bloc.state.canAnswer, isFalse);
    await bloc.close();
  });

  test('fails when the task cannot load', () async {
    repository.projectTaskResult = const Failed(NotFoundFailure());
    final bloc = buildBloc()
      ..add(const ClientTaskDetailsFetched(projectId: 'p-3', taskId: 't-5'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientTaskDetailsStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('accepting sends the answer, and the page can go back', () async {
    final bloc = await loadedBloc();

    bloc.add(const ClientTaskDetailsAnswered(TaskStatus.accepted));
    final state = await bloc.stream.firstWhere((s) => s.answered != null);
    expect(repository.taskStatuses, [('t-5', TaskStatus.accepted)]);
    expect(state.answered, TaskStatus.accepted);
    expect(state.answering, isNull);
    await bloc.close();
  });

  test('a refused answer reads the task again and says why', () async {
    final bloc = await loadedBloc();
    repository
      ..setTaskStatusResult = const Failed(ConflictFailure())
      ..projectTaskResult = Success(task(TaskStatus.rejected));

    bloc.add(const ClientTaskDetailsAnswered(TaskStatus.accepted));
    final state = await bloc.stream.firstWhere((s) => s.errorKey != null);
    expect(state.errorKey, 'errors.conflict');
    expect(state.answered, isNull);
    expect(state.answering, isNull);
    expect(state.task?.status, TaskStatus.rejected);
    await bloc.close();
  });
}
