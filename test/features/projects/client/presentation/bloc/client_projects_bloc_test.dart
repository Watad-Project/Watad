import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  test('emits LoadInProgress then LoadSuccess on fetch', () async {
    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: Success([
        ClientProject(
          id: 'p1',
          title: 'Residential Villa',
          status: ProjectStatus.open,
          city: 'Riyadh',
          pendingOfferCount: 3,
          createdAt: DateTime.utc(2026, 10, 14),
        ),
      ]),
    );

    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsLoadInProgress>(),
        isA<ClientProjectsLoadSuccess>().having(
          (s) => s.projects.length,
          'projects length',
          1,
        ),
      ]),
    );

    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure on error', () async {
    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: const Failed(NetworkFailure()),
    );

    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsLoadInProgress>(),
        isA<ClientProjectsLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ]),
    );

    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });
}
