import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_by_id_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  final sampleProject = ClientProject(
    id: 'proj-1',
    title: 'Villa',
    status: ProjectStatus.open,
    city: 'Riyadh',
    pendingOfferCount: 0,
    createdAt: DateTime.utc(2026, 10, 14),
  );

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());

    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: const Success([]),
      projectResult: Success(sampleProject),
      offersResult: const Success([]),
    );

    getIt
      ..registerFactory(
        () => ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo)),
      )
      ..registerFactory(
        () => ClientProjectOffersBloc(
          ClientGetProjectByIdUseCase(fakeRepo),
          ClientGetProjectOffersUseCase(fakeRepo),
          ClientAcceptOfferUseCase(fakeRepo),
        ),
      );
  });

  tearDown(getIt.reset);

  testWidgets('every client projects route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(ClientProjectsRoutes.projectsName);
    await tester.pumpAndSettle();
    expect(currentPath(router), ClientProjectsRoutes.projectsPath);
    expect(find.byType(ClientProjectsPage), findsOneWidget);

    router.goNamed(
      ClientProjectsRoutes.projectOffersName,
      pathParameters: {'id': 'proj-1'},
    );
    await tester.pumpAndSettle();
    expect(
      currentPath(router),
      ClientProjectsRoutes.projectOffersPath.replaceAll(':id', 'proj-1'),
    );
    expect(find.byType(ClientProjectOffersPage), findsOneWidget);
  });
}
