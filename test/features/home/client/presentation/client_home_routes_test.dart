import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/features/home/client/presentation/pages/client_home_page.dart';

import '../../../../helpers/fake_client_home_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    registerFakeClientHomeBloc(FakeClientHomeRepository());
  });

  tearDown(getIt.reset);

  testWidgets('client home route opens its page at its path', (tester) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(ClientHomeRoutes.homeName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientHomeRoutes.homePath);
    expect(find.byType(ClientHomePage), findsOneWidget);
  });
}
