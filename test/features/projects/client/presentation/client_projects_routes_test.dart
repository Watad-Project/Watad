import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_address_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    registerFakeAuthBloc(FakeAuthRepository());
    getIt.registerFactory(ClientPostProjectBloc.new);
  });

  tearDown(getIt.reset);

  testWidgets('every client projects route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: ClientProjectsRoutes.postProjectPath,
    );

    router.goNamed(ClientProjectsRoutes.postProjectName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientProjectsRoutes.postProjectPath);
    expect(find.byType(ClientPostProjectPage), findsOneWidget);

    router.goNamed(ClientProjectsRoutes.postProjectAddressName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientProjectsRoutes.postProjectAddressPath);
    expect(find.byType(ClientPostProjectAddressPage), findsOneWidget);
  });
}
