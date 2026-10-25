import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_tasks_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_tasks_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  ClientProject project(ProjectStatus status) => ClientProject(
    id: 'p-1',
    title: 'بناء ملحق',
    status: status,
    city: 'جدة',
    pendingOfferCount: 0,
    createdAt: DateTime.utc(2026, 10, 17),
  );
  const task = ClientProjectTask(
    id: 't-1',
    title: 'اللياسة الداخلية',
    description: 'لياسة الجدران الداخلية',
    status: TaskStatus.accepted,
  );

  late FakeClientProjectsRepository repository;

  ClientProjectTasksBloc buildBloc() => ClientProjectTasksBloc(
    ClientGetProjectUseCase(repository),
    ClientGetProjectTasksUseCase(repository),
  );

  setUp(() {
    repository = FakeClientProjectsRepository()
      ..projectResult = Success(project(ProjectStatus.inProgress))
      ..projectTasksResult = const Success([task]);
  });

  test('loads the project and its tasks', () async {
    final bloc = buildBloc()..add(const ClientProjectTasksFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectTasksStatus.success,
    );
    expect(state.project?.title, 'بناء ملحق');
    expect(state.tasks.single.id, 't-1');
    expect(state.canPay, isTrue);
    await bloc.close();
  });

  test('a project waiting for offers has nothing to pay yet', () async {
    repository.projectResult = Success(project(ProjectStatus.open));
    final bloc = buildBloc()..add(const ClientProjectTasksFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectTasksStatus.success,
    );
    expect(state.canPay, isFalse);
    await bloc.close();
  });

  test('fails when the tasks cannot load', () async {
    repository.projectTasksResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ClientProjectTasksFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectTasksStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    expect(state.project, isNull);
    await bloc.close();
  });

  test('a refresh keeps the tasks it has while it fails', () async {
    final bloc = buildBloc()..add(const ClientProjectTasksFetched('p-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectTasksStatus.success,
    );
    repository.projectResult = const Failed(NotFoundFailure());

    bloc.add(const ClientProjectTasksFetched('p-1'));
    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectTasksStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    expect(state.tasks.single.id, 't-1');
    await bloc.close();
  });
}
