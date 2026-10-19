import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_contractors_bloc.dart';

import '../../../../../helpers/fake_client_home_repository.dart';

void main() {
  List<ClientContractor> page(int count, {int from = 0}) => [
    for (var i = from; i < from + count; i++)
      ClientContractor(id: 'c-$i', companyName: 'مقاول $i', ratingCount: 0),
  ];

  late FakeClientHomeRepository repository;

  ClientContractorsBloc buildBloc() =>
      ClientContractorsBloc(ClientGetContractorsUseCase(repository));

  Future<ClientContractorsState> settled(ClientContractorsBloc bloc) =>
      bloc.stream.firstWhere(
        (s) => s.status != ClientContractorsStatus.loading && !s.isLoadingMore,
      );

  setUp(() => repository = FakeClientHomeRepository());

  test('loads the first page', () async {
    repository.contractorsPageResult = Success(page(3));
    final bloc = buildBloc()..add(const ClientContractorsFetched());

    final state = await settled(bloc);
    expect(state.status, ClientContractorsStatus.success);
    expect(state.contractors, hasLength(3));
    expect(state.hasMore, isFalse);
    expect(repository.queries.single.offset, 0);
    expect(repository.queries.single.limit, ClientContractorsBloc.pageSize);
    await bloc.close();
  });

  test('shows the failure when the list cannot load', () async {
    repository.contractorsPageResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ClientContractorsFetched());

    final state = await settled(bloc);
    expect(state.status, ClientContractorsStatus.failure);
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a full page asks for the next one at the end', () async {
    repository.contractorsPageResult = Success(
      page(ClientContractorsBloc.pageSize),
    );
    final bloc = buildBloc()..add(const ClientContractorsFetched());
    expect((await settled(bloc)).hasMore, isTrue);

    repository.contractorsPageResult = Success(
      page(2, from: ClientContractorsBloc.pageSize),
    );
    bloc.add(const ClientContractorsMoreRequested());
    final state = await bloc.stream.firstWhere(
      (s) => !s.isLoadingMore && s.contractors.length > 20,
    );
    expect(state.contractors, hasLength(ClientContractorsBloc.pageSize + 2));
    expect(state.hasMore, isFalse);
    expect(repository.queries.last.offset, ClientContractorsBloc.pageSize);
    await bloc.close();
  });

  test('a new filter starts again from the first page', () async {
    repository.contractorsPageResult = Success(page(3));
    final bloc = buildBloc()..add(const ClientContractorsFetched());
    await settled(bloc);

    const filter = ClientContractorFilter(query: 'البناء', minRating: 4);
    bloc.add(const ClientContractorsFilterChanged(filter));
    final state = await bloc.stream.firstWhere(
      (s) => s.filter == filter && s.status == ClientContractorsStatus.success,
    );
    expect(state.filter, filter);
    expect(repository.queries.last.filter, filter);
    expect(repository.queries.last.offset, 0);
    await bloc.close();
  });
}
