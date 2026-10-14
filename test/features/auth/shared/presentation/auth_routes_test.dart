import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    final authRepository = FakeAuthRepository();
    registerFakeAuthBloc(authRepository);
    getIt
      ..registerFactory(RoleBloc.new)
      ..registerFactory(
        () => BusinessSignUpBloc(
          CheckEmailRegisteredUseCase(authRepository),
          SaveBusinessSignUpUseCase(authRepository),
        ),
      );
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

    // Selecting contractor and continuing routes to business signup
    await tester.tap(find.text('مقاول'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'متابعة'));
    await tester.pumpAndSettle();

    expect(currentPath(router), AuthRoutes.signUpBusinessPath);
    expect(find.byType(SignUpBusinessPage), findsOneWidget);
  });
}
