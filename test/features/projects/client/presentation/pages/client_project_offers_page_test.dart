import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_offer_card.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';
import '../../../../../helpers/pump_component.dart';

void main() {
  final sampleProject = ClientProject(
    id: 'proj-1',
    title: 'Residential Villa',
    status: ProjectStatus.open,
    city: 'Riyadh',
    district: 'Al-Yasmin',
    pendingOfferCount: 1,
    createdAt: DateTime.utc(2026, 10, 14),
    budget: const Money.halalas(50000000),
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
    message: 'Includes exterior finishing',
  );

  testWidgets('shows offer cards and project details header', (tester) async {
    final fakeRepo = FakeClientProjectsRepository(
      projectResult: Success(sampleProject),
      offersResult: Success([sampleOffer]),
    );

    final bloc = ClientProjectOffersBloc(
      ClientGetProjectByIdUseCase(fakeRepo),
      ClientGetProjectOffersUseCase(fakeRepo),
      ClientAcceptOfferUseCase(fakeRepo),
    )..add(const ClientProjectOffersFetched('proj-1'));

    await pumpLocalizedApp(
      tester,
      BlocProvider<ClientProjectOffersBloc>.value(
        value: bloc,
        child: const ClientProjectOffersPage(projectId: 'proj-1'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Residential Villa — Al-Yasmin'), findsOneWidget);
    expect(find.byType(ClientOfferCard), findsOneWidget);
    expect(find.text('Al-Bina Contracting'), findsOneWidget);
    expect(find.text('قبول العرض'), findsOneWidget);
    expect(find.text('مراسلة'), findsOneWidget);
  });

  testWidgets('shows empty view when project has no offers', (tester) async {
    final fakeRepo = FakeClientProjectsRepository(
      projectResult: Success(sampleProject),
      offersResult: const Success<List<ClientProjectOffer>>([]),
    );

    final bloc = ClientProjectOffersBloc(
      ClientGetProjectByIdUseCase(fakeRepo),
      ClientGetProjectOffersUseCase(fakeRepo),
      ClientAcceptOfferUseCase(fakeRepo),
    )..add(const ClientProjectOffersFetched('proj-1'));

    await pumpLocalizedApp(
      tester,
      BlocProvider<ClientProjectOffersBloc>.value(
        value: bloc,
        child: const ClientProjectOffersPage(projectId: 'proj-1'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('لا توجد عروض واردة'), findsOneWidget);
  });

  testWidgets('shows error view on failure', (tester) async {
    final fakeRepo = FakeClientProjectsRepository(
      projectResult: const Failed<ClientProject>(
        NotFoundFailure('errors.not_found'),
      ),
    );

    final bloc = ClientProjectOffersBloc(
      ClientGetProjectByIdUseCase(fakeRepo),
      ClientGetProjectOffersUseCase(fakeRepo),
      ClientAcceptOfferUseCase(fakeRepo),
    )..add(const ClientProjectOffersFetched('proj-1'));

    await pumpLocalizedApp(
      tester,
      BlocProvider<ClientProjectOffersBloc>.value(
        value: bloc,
        child: const ClientProjectOffersPage(projectId: 'proj-1'),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
