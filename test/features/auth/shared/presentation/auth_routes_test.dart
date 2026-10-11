import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  @override
  Future<Result<bool>> isEmailRegistered(String email) async =>
      const Success(false);

  @override
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data) async =>
      const Success(null);
}

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository();

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      const Success(SplashDestination.login);
}

void main() {
  testWidgets('every auth route opens its page at its path', (tester) async {
    const authRepository = FakeAuthRepository();
    const splashRepository = FakeSplashRepository();

    getIt
      ..registerFactory(
        () => SplashBloc(const GetInitialDestinationUseCase(splashRepository)),
      )
      ..registerFactory(
        () => BusinessSignUpBloc(
          const CheckEmailRegisteredUseCase(authRepository),
          const SaveBusinessSignUpUseCase(authRepository),
        ),
      );
    addTearDown(getIt.reset);

    final router = await pumpAppRouter(tester);

    router.goNamed(AuthRoutes.signUpBusinessName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.signUpBusinessPath);
    expect(find.byType(SignUpBusinessPage), findsOneWidget);
  });
}
