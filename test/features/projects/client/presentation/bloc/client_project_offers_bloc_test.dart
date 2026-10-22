import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  ClientProject project(ProjectStatus status) => ClientProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: status,
    city: 'المدينة المنورة',
    pendingOfferCount: 1,
    createdAt: DateTime.utc(2026, 10, 18),
  );
  ClientProjectOffer offer(OfferStatus status) => ClientProjectOffer(
    id: 'o-1',
    projectId: 'p-1',
    amount: const Money.halalas(46500000),
    status: status,
    providerName: 'مؤسسة البناء المتين',
    isProviderVerified: true,
    providerRatingCount: 0,
    createdAt: DateTime.utc(2026, 10, 18),
  );

  late FakeClientProjectsRepository repository;

  ClientProjectOffersBloc buildBloc() => ClientProjectOffersBloc(
    ClientGetProjectUseCase(repository),
    ClientGetProjectOffersUseCase(repository),
    ClientAcceptOfferUseCase(repository),
  );

  Future<ClientProjectOffersBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ClientProjectOffersFetched('p-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectOffersStatus.success,
    );
    return bloc;
  }

  setUp(() {
    repository = FakeClientProjectsRepository()
      ..projectResult = Success(project(ProjectStatus.open))
      ..offersResult = Success([offer(OfferStatus.pending)]);
  });

  test('loads the project and its offers', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.project?.title, 'فيلا سكنية');
    expect(bloc.state.offers.single.id, 'o-1');
    expect(bloc.state.canAccept(bloc.state.offers.single), isTrue);
    await bloc.close();
  });

  test('fails when the project cannot load', () async {
    repository.projectResult = const Failed(NotFoundFailure());
    final bloc = buildBloc()..add(const ClientProjectOffersFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectOffersStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('accepting sends the amount seen and reads the result back', () async {
    final bloc = await loadedBloc();
    repository
      ..projectResult = Success(project(ProjectStatus.inProgress))
      ..offersResult = Success([offer(OfferStatus.accepted)]);

    bloc.add(ClientProjectOfferAccepted(bloc.state.offers.single));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.accepted, [('o-1', 46500000)]);
    expect(state.project?.status, ProjectStatus.inProgress);
    expect(state.canAccept(state.offers.single), isFalse);
    expect(state.acceptingOfferId, isNull);
    expect(state.message?.key, 'projects.client.offer_accepted');
    expect(state.message?.isError, isFalse);
    await bloc.close();
  });

  test('a refused accept shows the server\'s reason', () async {
    final bloc = await loadedBloc();
    repository.acceptResult = const Failed(ConflictFailure());

    bloc.add(ClientProjectOfferAccepted(bloc.state.offers.single));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'errors.conflict');
    expect(state.message?.isError, isTrue);
    expect(state.offers.single.status, OfferStatus.pending);
    await bloc.close();
  });
}
