import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeClientProjectsRepository repository;

  setUp(() {
    repository = FakeClientProjectsRepository();
    registerFakeClientProjectsBloc(repository);
    registerFakeClientProjectOffersBloc(repository);
  });
  tearDown(getIt.reset);

  testWidgets('every client projects route opens its page at its path', (
    tester,
  ) async {
    final session = FakeAppSession()..signIn(AppRole.client);
    final router = await pumpAppRouter(
      tester,
      session: session,
      initialLocation: ClientProjectsRoutes.projectsPath,
    );

    router.goNamed(ClientProjectsRoutes.projectsName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientProjectsRoutes.projectsPath);
    expect(find.byType(ClientProjectsPage), findsOneWidget);

    router.goNamed(
      ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': 'proj-1'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/client/projects/proj-1/offers');
    expect(find.byType(ClientProjectOffersPage), findsOneWidget);
  });
}
