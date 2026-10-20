import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  final project = ClientProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.open,
    city: 'المدينة المنورة',
    pendingOfferCount: 3,
    createdAt: DateTime.utc(2026, 10, 18),
  );

  late FakeClientProjectsRepository repository;

  setUp(() => repository = FakeClientProjectsRepository());

  test('loads the projects', () async {
    repository.projectsResult = Success([project]);
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(repository));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsState>().having(
          (s) => s.status,
          'status',
          ClientProjectsStatus.loading,
        ),
        isA<ClientProjectsState>()
            .having((s) => s.status, 'status', ClientProjectsStatus.success)
            .having((s) => s.projects, 'projects', [project]),
      ]),
    );
    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });

  test('a failed reload keeps the list on screen', () async {
    repository.projectsResult = Success([project]);
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(repository))
      ..add(const ClientProjectsFetched());
    await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectsStatus.success,
    );

    repository.projectsResult = const Failed(NetworkFailure());
    bloc.add(const ClientProjectsFetched());
    final state = await bloc.stream.first;
    expect(state.status, ClientProjectsStatus.failure);
    expect(state.failure, isA<NetworkFailure>());
    expect(state.projects, [project]);
    await bloc.close();
  });
}
