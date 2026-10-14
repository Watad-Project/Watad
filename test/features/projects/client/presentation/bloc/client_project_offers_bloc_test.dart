import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
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
  final sampleProject = ClientProject(
    id: 'proj-1',
    title: 'Residential Villa',
    status: ProjectStatus.open,
    city: 'Riyadh',
    district: 'Al-Yasmin',
    pendingOfferCount: 1,
    createdAt: DateTime.utc(2026, 10, 14),
  );

  final sampleOffer = ClientProjectOffer(
    id: 'offer-1',
    projectId: 'proj-1',
    contractorName: 'Al-Bina Contracting',
    contractorRating: 4.8,
    isContractorVerified: true,
    amount: const Money.halalas(46500000),
    durationMonths: 7,
    status: OfferStatus.pending,
    createdAt: DateTime.utc(2026, 10, 14),
  );

  test('emits LoadInProgress then LoadSuccess on fetch', () async {
    final fakeRepo = FakeClientProjectsRepository(
      projectResult: Success(sampleProject),
      offersResult: Success([sampleOffer]),
    );

    final bloc = ClientProjectOffersBloc(
      ClientGetProjectByIdUseCase(fakeRepo),
      ClientGetProjectOffersUseCase(fakeRepo),
      ClientAcceptOfferUseCase(fakeRepo),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectOffersLoadInProgress>(),
        isA<ClientProjectOffersLoadSuccess>()
            .having((s) => s.project.id, 'project id', 'proj-1')
            .having((s) => s.offers.length, 'offers length', 1),
      ]),
    );

    bloc.add(const ClientProjectOffersFetched('proj-1'));
    await states;
    await bloc.close();
  });

  test(
    'emits LoadInProgress then LoadFailure when project not found',
    () async {
      final fakeRepo = FakeClientProjectsRepository(
        projectResult: const Failed(NotFoundFailure('errors.not_found')),
        offersResult: Success([sampleOffer]),
      );

      final bloc = ClientProjectOffersBloc(
        ClientGetProjectByIdUseCase(fakeRepo),
        ClientGetProjectOffersUseCase(fakeRepo),
        ClientAcceptOfferUseCase(fakeRepo),
      );

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

  test('updates state with acceptedOfferId on offer acceptance', () async {
    final fakeRepo = FakeClientProjectsRepository(
      projectResult: Success(sampleProject),
      offersResult: Success([sampleOffer]),
      acceptOfferResult: const Success(null),
    );

    final bloc = ClientProjectOffersBloc(
      ClientGetProjectByIdUseCase(fakeRepo),
      ClientGetProjectOffersUseCase(fakeRepo),
      ClientAcceptOfferUseCase(fakeRepo),
    );

    bloc.add(const ClientProjectOffersFetched('proj-1'));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<ClientProjectOffersLoadSuccess>()),
    );

    final states = expectLater(
      bloc.stream,
      emits(
        isA<ClientProjectOffersLoadSuccess>().having(
          (s) => s.acceptedOfferId,
          'acceptedOfferId',
          'offer-1',
        ),
      ),
    );

    bloc.add(
      const ClientProjectOfferAccepted(
        offerId: 'offer-1',
        expectedAmount: Money.halalas(46500000),
      ),
    );

    await states;
    expect(fakeRepo.lastAcceptedOfferId, 'offer-1');
    await bloc.close();
  });
}
