import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';

/// A hand-written [AuthRepository]: it answers with the results you set and
/// records every call (APP_ARCHITECTURE.md §16).
class FakeAuthRepository implements AuthRepository {
  Result<void> sendOtpResult = const Success(null);

  Result<AuthSession> verifyOtpResult = const Success(
    AuthSession(userId: 'user-1', email: 'user@watad.sa'),
  );

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
}

/// For tests that open the login route: the route builder takes its
/// [AuthBloc] from getIt (APP_ARCHITECTURE.md §12). Reset getIt after the
/// test.
void registerFakeAuthBloc(FakeAuthRepository repository) {
  getIt.registerFactory(
    () => AuthBloc(SendOtpUseCase(repository), VerifyOtpUseCase(repository)),
  );
}
