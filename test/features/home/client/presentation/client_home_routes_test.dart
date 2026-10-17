import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/home/client/client_home_injection.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';
import 'package:watad/features/home/client/presentation/pages/client_home_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_home_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    registerClientHomeDependencies(getIt);
    getIt.unregister<ClientHomeRepository>();
    getIt.registerLazySingleton<ClientHomeRepository>(
      FakeClientHomeRepository.new,
    );
  });

  tearDown(getIt.reset);

  testWidgets('client home route opens ClientHomePage at /client/home', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );

    router.goNamed(ClientHomeRoutes.homeName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientHomeRoutes.homePath);
    expect(find.byType(ClientHomePage), findsOneWidget);
  });
}
