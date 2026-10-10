import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthBloc bloc;

  setUp(() {
    repository = FakeAuthRepository();
    bloc = AuthBloc(SendOtpUseCase(repository), VerifyOtpUseCase(repository));
  });

  tearDown(() => bloc.close());

  /// Adds [events] and returns the state once [until] holds.
  Future<AuthState> run(
    List<AuthEvent> events,
    bool Function(AuthState state) until,
  ) {
    final reached = bloc.stream.firstWhere(until);
    events.forEach(bloc.add);
    return reached;
  }

  Future<AuthState> sendCode() => run(const [
    AuthEmailChanged('user@watad.sa'),
    AuthOtpRequested(),
  ], (s) => s.codeSent);

  test('starts idle, with no code sent', () {
    expect(bloc.state.status, AuthStatus.idle);
    expect(bloc.state.codeSent, isFalse);
  });

  group('asking for a code', () {
    test('with an invalid email shows the email error', () async {
      final state = await run(const [
        AuthEmailChanged('not-an-email'),
        AuthOtpRequested(),
      ], (s) => s.emailError != null);

      expect(state.emailError, 'auth.invalid_email_error');
      expect(state.codeSent, isFalse);
      expect(repository.sentTo, isEmpty);
    });

    test('sends it and starts the resend countdown', () async {
      final state = await sendCode();

      expect(repository.sentTo, ['user@watad.sa']);
      expect(state.successMessage, 'auth.otp_sent_success');
      expect(state.resendSeconds, AuthBloc.resendCooldownSeconds);
      expect(state.canResend, isFalse);
    });

    test('for an email without an account says so', () async {
      repository.sendOtpResult = const Failed(AuthFailure());

      final state = await run(const [
        AuthEmailChanged('nobody@watad.sa'),
        AuthOtpRequested(),
      ], (s) => s.errorMessage != null);

      expect(state.errorMessage, 'auth.no_account_error');
      expect(state.codeSent, isFalse);
    });

    test('too often shows the rate limit message', () async {
      repository.sendOtpResult = const Failed(RateLimitFailure());

      final state = await run(const [
        AuthEmailChanged('user@watad.sa'),
        AuthOtpRequested(),
      ], (s) => s.errorMessage != null);

      expect(state.errorMessage, 'errors.rate_limit');
    });

    test('again during the countdown sends nothing', () async {
      await sendCode();
      bloc.add(const AuthOtpRequested());
      await pumpEventQueue();

      expect(repository.sentTo, ['user@watad.sa']);
    });

    test('the countdown counts down each second', () async {
      await sendCode();

      final state = await run(const [
        AuthCountdownTicked(),
      ], (s) => s.resendSeconds < AuthBloc.resendCooldownSeconds);

      expect(state.resendSeconds, AuthBloc.resendCooldownSeconds - 1);
    });
  });

  test('changing the email after a code was sent starts over', () async {
    await sendCode();

    final state = await run(const [
      AuthEmailChanged('other@watad.sa'),
    ], (s) => s.email == 'other@watad.sa');

    expect(state.codeSent, isFalse);
    expect(state.resendSeconds, 0);
  });

  group('checking the code', () {
    test('an incomplete code shows the code error', () async {
      await sendCode();

      final state = await run(const [
        AuthOtpChanged('1234'),
        AuthOtpSubmitted(),
      ], (s) => s.otpError != null);

      expect(state.otpError, 'auth.invalid_otp_error');
      expect(repository.checked, isEmpty);
    });

    test('a wrong or expired code shows its error', () async {
      repository.verifyOtpResult = const Failed(AuthFailure());
      await sendCode();

      final state = await run(const [
        AuthOtpChanged('482910'),
        AuthOtpSubmitted(),
      ], (s) => s.otpError != null);

      expect(state.otpError, 'auth.otp_expired_or_invalid');
      expect(state.status, AuthStatus.idle);
    });

    test('no connection shows the network message', () async {
      repository.verifyOtpResult = const Failed(NetworkFailure());
      await sendCode();

      final state = await run(const [
        AuthOtpChanged('482910'),
        AuthOtpSubmitted(),
      ], (s) => s.errorMessage != null);

      expect(state.errorMessage, 'errors.network');
      expect(state.otpError, isNull);
    });

    test('the right code signs the user in', () async {
      await sendCode();

      final state = await run(const [
        AuthOtpChanged('482910'),
        AuthOtpSubmitted(),
      ], (s) => s.status == AuthStatus.signedIn);

      expect(repository.checked, [('user@watad.sa', '482910')]);
      expect(state.successMessage, 'auth.signed_in');
    });

    test('before a code was sent does nothing', () async {
      bloc
        ..add(const AuthEmailChanged('user@watad.sa'))
        ..add(const AuthOtpChanged('482910'))
        ..add(const AuthOtpSubmitted());
      await pumpEventQueue();

      expect(repository.checked, isEmpty);
    });
  });
}
