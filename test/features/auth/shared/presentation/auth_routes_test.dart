import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_user_profile_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/sign_up_client_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository(this.result);
  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<bool>> isEmailRegistered(String email) async =>
      const Success(false);

  @override
  Future<Result<void>> sendSignUpOtp(String email) async => const Success(null);

  @override
  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params) async =>
      const Success(
        AuthSession(userId: 'test-user', email: 'test@example.com'),
      );

  @override
  Future<Result<void>> saveProfile(SignUpProfile profile) async =>
      const Success(null);
}

void main() {
  testWidgets('every auth route opens its page at its path', (tester) async {
    final fakeRepo = FakeAuthRepository();
    getIt.registerFactory(
      () => SplashBloc(
        const GetInitialDestinationUseCase(
          FakeSplashRepository(Success(SplashDestination.login)),
        ),
      ),
    );
    getIt.registerFactory(
      () => SignUpClientBloc(
        checkEmailRegistered: CheckEmailRegisteredUseCase(fakeRepo),
        sendSignUpOtp: SendSignUpOtpUseCase(fakeRepo),
        verifySignUpOtp: VerifySignUpOtpUseCase(fakeRepo),
        saveUserProfile: SaveUserProfileUseCase(fakeRepo),
      ),
    );
    addTearDown(getIt.reset);

    final router = await pumpAppRouter(tester);

    router.goNamed(AuthRoutes.signUpClientName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.signUpClientPath);
    expect(find.byType(SignUpClientPage), findsOneWidget);
  });
}
