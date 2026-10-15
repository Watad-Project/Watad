import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_user_profile_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/sign_out_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/sign_up_client_bloc.dart';

/// A hand-written [AuthRepository]: it answers with the results you set and
/// records every call (APP_ARCHITECTURE.md §16).
class FakeAuthRepository implements AuthRepository {
  Result<void> sendOtpResult = const Success(null);

  Result<AuthSession> verifyOtpResult = const Success(
    AuthSession(userId: 'user-1', email: 'user@watad.sa'),
  );

  Result<void> sendSignUpOtpResult = const Success(null);
  Result<AuthSession> verifySignUpOtpResult = const Success(
    AuthSession(userId: 'user-1', email: 'user@watad.sa'),
  );
  Result<String> saveProfileResult = const Success('created');
  Result<void> signOutResult = const Success(null);

  /// The emails a code was sent to.
  final List<String> sentTo = [];

  /// The codes that were checked, as (email, token).
  final List<(String, String)> checked = [];

  @override
  Future<Result<void>> sendOtp({required String email}) async {
    sentTo.add(email);
    return sendOtpResult;
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async {
    checked.add((email, token));
    return verifyOtpResult;
  }

  @override
  Future<Result<void>> sendSignUpOtp(String email) async => sendSignUpOtpResult;

  @override
  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params) async =>
      verifySignUpOtpResult;

  @override
  Future<Result<String>> saveProfile(SignUpProfile profile) async =>
      saveProfileResult;

  @override
  Future<Result<void>> signOut() async => signOutResult;
}

/// For tests that open the login route: the route builder takes its
/// [AuthBloc] from getIt (APP_ARCHITECTURE.md §12). Reset getIt after the
/// test.
void registerFakeAuthBloc(FakeAuthRepository repository) {
  getIt.registerFactory(
    () => AuthBloc(SendOtpUseCase(repository), VerifyOtpUseCase(repository)),
  );
}

/// For tests that open the sign up client route: the route builder takes its
/// [SignUpClientBloc] from getIt (APP_ARCHITECTURE.md §12). Reset getIt after the
/// test.
void registerFakeSignUpClientBloc(FakeAuthRepository repository) {
  getIt.registerFactory(
    () => SignUpClientBloc(
      sendSignUpOtp: SendSignUpOtpUseCase(repository),
      verifySignUpOtp: VerifySignUpOtpUseCase(repository),
      saveUserProfile: SaveUserProfileUseCase(repository),
      signOut: SignOutUseCase(repository),
    ),
  );
}
