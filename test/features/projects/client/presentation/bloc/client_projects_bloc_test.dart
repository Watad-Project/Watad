import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  late FakeClientProjectsRepository repository;

  setUp(() {
    repository = FakeClientProjectsRepository();
  });

  test('emits LoadInProgress then LoadSuccess on fetch', () async {
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(repository));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsLoadInProgress>(),
        isA<ClientProjectsLoadSuccess>(),
      ]),
    );

    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure on error', () async {
    repository.getMyProjectsResult = const Failed<List<ClientProject>>(
      NetworkFailure(),
    );
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(repository));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsLoadInProgress>(),
        isA<ClientProjectsLoadFailure>(),
      ]),
    );

    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });
}
