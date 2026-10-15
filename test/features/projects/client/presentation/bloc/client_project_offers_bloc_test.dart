import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_by_id_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  late FakeClientProjectsRepository repository;

  setUp(() {
    repository = FakeClientProjectsRepository();
  });

  ClientProjectOffersBloc buildBloc() => ClientProjectOffersBloc(
    ClientGetProjectByIdUseCase(repository),
    ClientGetProjectOffersUseCase(repository),
    ClientAcceptOfferUseCase(repository),
  );

  test('emits LoadInProgress then LoadSuccess when fetching offers', () async {
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectOffersLoadInProgress>(),
        isA<ClientProjectOffersLoadSuccess>(),
      ]),
    );

    bloc.add(const ClientProjectOffersFetched('proj-1'));
    await states;
    await bloc.close();
  });

  test(
    'emits LoadInProgress then LoadFailure when project fetch fails',
    () async {
      repository.getProjectByIdResult = const Failed<ClientProject>(
        NetworkFailure(),
      );
      final bloc = buildBloc();

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ClientProjectOffersLoadInProgress>(),
          isA<ClientProjectOffersLoadFailure>(),
        ]),
      );

      bloc.add(const ClientProjectOffersFetched('proj-1'));
      await states;
      await bloc.close();
    },
  );

  test(
    'emits LoadInProgress then LoadFailure when offers fetch fails',
    () async {
      repository.getProjectOffersResult =
          const Failed<List<ClientProjectOffer>>(ServerFailure());
      final bloc = buildBloc();

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ClientProjectOffersLoadInProgress>(),
          isA<ClientProjectOffersLoadFailure>(),
        ]),
      );

      bloc.add(const ClientProjectOffersFetched('proj-1'));
      await states;
      await bloc.close();
    },
  );

  test('emits AcceptSuccess when accepting an offer succeeds', () async {
    final bloc = buildBloc();

    bloc.add(const ClientProjectOffersFetched('proj-1'));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<ClientProjectOffersLoadSuccess>()),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectOffersLoadSuccess>(),
        isA<ClientProjectOfferAcceptSuccess>(),
      ]),
    );

    bloc.add(
      const ClientProjectOfferAccepted(
        projectId: 'proj-1',
        offerId: 'offer-1',
        expectedAmount: Money.halalas(4500000),
      ),
    );
    await states;
    expect(repository.acceptedParams.length, 1);
    expect(repository.acceptedParams.first.offerId, 'offer-1');
    await bloc.close();
  });

  test('emits AcceptFailure when accepting an offer fails', () async {
    repository.acceptOfferResult = const Failed<void>(ConflictFailure());
    final bloc = buildBloc();

    bloc.add(const ClientProjectOffersFetched('proj-1'));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<ClientProjectOffersLoadSuccess>()),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectOffersLoadSuccess>(),
        isA<ClientProjectOfferAcceptFailure>(),
      ]),
    );

    bloc.add(
      const ClientProjectOfferAccepted(
        projectId: 'proj-1',
        offerId: 'offer-1',
        expectedAmount: Money.halalas(4500000),
      ),
    );
    await states;
    await bloc.close();
  });
}
