import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
    registerFakeAuthBloc(repository);
    registerFakeSignUpClientBloc(repository);
    getIt.registerFactory<RoleBloc>(() => RoleBloc());
  });
  tearDown(getIt.reset);

  testWidgets('every auth route opens its page at its path', (tester) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: AuthRoutes.loginPath,
    );

    router.goNamed(AuthRoutes.loginName);
    await tester.pumpAndSettle();

    expect(currentPath(router), AuthRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);

    router.goNamed(AuthRoutes.roleName);
    await tester.pumpAndSettle();

    expect(currentPath(router), AuthRoutes.rolePath);
    expect(find.byType(RolePage), findsOneWidget);

    router.goNamed(AuthRoutes.signUpClientName);
    await tester.pumpAndSettle();

    expect(currentPath(router), AuthRoutes.signUpClientPath);
    expect(find.byType(SignUpClientPage), findsOneWidget);
  });
}
