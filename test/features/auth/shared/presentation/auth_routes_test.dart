import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() => registerFakeAuthBloc(FakeAuthRepository()));
  tearDown(getIt.reset);

  testWidgets('every auth route opens its page at its path', (tester) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(AuthRoutes.loginName);
    await tester.pumpAndSettle();

    expect(currentPath(router), AuthRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
