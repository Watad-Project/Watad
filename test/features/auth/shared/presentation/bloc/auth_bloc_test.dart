import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.sendOtpResult = const Success(null),
    this.verifyOtpResult = const Success(AuthSession(userId: 'u1')),
  });

  Result<void> sendOtpResult;
  Result<AuthSession> verifyOtpResult;

  @override
  Future<Result<void>> sendOtp({required String email}) async => sendOtpResult;

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => verifyOtpResult;
}

void main() {
  late FakeAuthRepository repository;
  late SendOtpUseCase sendOtp;
  late VerifyOtpUseCase verifyOtp;
  late AuthBloc bloc;

  setUp(() {
    repository = FakeAuthRepository();
    sendOtp = SendOtpUseCase(repository);
    verifyOtp = VerifyOtpUseCase(repository);
    bloc = AuthBloc(sendOtp, verifyOtp);
  });

  tearDown(() async {
    await bloc.close();
  });

  test('initial state has 28 resend seconds and initial status', () {
    expect(bloc.state.status, AuthStatus.initial);
    expect(bloc.state.resendSeconds, 28);
    expect(bloc.state.email, '');
    expect(bloc.state.otp, '');
  });

  test('AuthEmailChanged updates email and clears emailError', () {
    bloc.add(const AuthEmailChanged('user@watad.sa'));
    expectLater(
      bloc.stream,
      emits(
        predicate<AuthState>(
          (s) => s.email == 'user@watad.sa' && s.emailError == null,
        ),
      ),
    );
  });

  test('AuthOtpChanged updates otp and clears otpError', () {
    bloc.add(const AuthOtpChanged('1234'));
    expectLater(
      bloc.stream,
      emits(predicate<AuthState>((s) => s.otp == '1234' && s.otpError == null)),
    );
  });

  test('AuthOtpSubmitted emits validation error for empty fields', () async {
    bloc.add(const AuthOtpSubmitted());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AuthState>((s) => s.status == AuthStatus.verifyingOtp),
        predicate<AuthState>(
          (s) =>
              s.emailError == 'auth.email_required_error' &&
              s.status == AuthStatus.initial,
        ),
      ]),
    );
  });

  test('AuthOtpSubmitted verifies successfully on valid inputs', () async {
    bloc.add(const AuthEmailChanged('user@watad.sa'));
    bloc.add(const AuthOtpChanged('1234'));
    bloc.add(const AuthOtpSubmitted());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AuthState>((s) => s.email == 'user@watad.sa'),
        predicate<AuthState>((s) => s.otp == '1234'),
        predicate<AuthState>((s) => s.status == AuthStatus.verifyingOtp),
        predicate<AuthState>(
          (s) => s.status == AuthStatus.verified && s.session?.userId == 'u1',
        ),
      ]),
    );
  });

  test('AuthOtpSubmitted emits server error failure message', () async {
    repository.verifyOtpResult = const Failed(AuthFailure());
    bloc.add(const AuthEmailChanged('user@watad.sa'));
    bloc.add(const AuthOtpChanged('1234'));
    bloc.add(const AuthOtpSubmitted());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AuthState>((s) => s.email == 'user@watad.sa'),
        predicate<AuthState>((s) => s.otp == '1234'),
        predicate<AuthState>((s) => s.status == AuthStatus.verifyingOtp),
        predicate<AuthState>(
          (s) => s.status == AuthStatus.initial && s.message == 'errors.auth',
        ),
      ]),
    );
  });
}
