import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_user_profile_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/sign_up_client_bloc.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.emailRegisteredResult = const Success(false),
    this.sendOtpResult = const Success(null),
    this.verifyOtpResult = const Success(
      AuthSession(userId: 'user-1', email: 'test@example.com'),
    ),
    this.saveProfileResult = const Success(null),
  });

  Result<bool> emailRegisteredResult;
  Result<void> sendOtpResult;
  Result<AuthSession> verifyOtpResult;
  Result<void> saveProfileResult;

  @override
  Future<Result<void>> sendOtp({required String email}) async =>
      const Success(null);

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => verifyOtpResult;

  @override
  Future<Result<bool>> isEmailRegistered(String email) async =>
      emailRegisteredResult;

  @override
  Future<Result<void>> sendSignUpOtp(String email) async => sendOtpResult;

  @override
  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params) async =>
      verifyOtpResult;

  @override
  Future<Result<void>> saveProfile(SignUpProfile profile) async =>
      saveProfileResult;
}

SignUpClientBloc buildBloc(FakeAuthRepository repository) {
  return SignUpClientBloc(
    checkEmailRegistered: CheckEmailRegisteredUseCase(repository),
    sendSignUpOtp: SendSignUpOtpUseCase(repository),
    verifySignUpOtp: VerifySignUpOtpUseCase(repository),
    saveUserProfile: SaveUserProfileUseCase(repository),
  );
}

void main() {
  group('SignUpClientBloc', () {
    test('initial state is correct', () async {
      final repo = FakeAuthRepository();
      final bloc = buildBloc(repo);

      expect(bloc.state.status, SignUpClientStatus.initial);
      expect(bloc.state.step, SignUpClientStep.form);
      expect(bloc.state.fullName, '');
      expect(bloc.state.termsAgreed, false);

      await bloc.close();
    });

    test('field changed events update state', () async {
      final repo = FakeAuthRepository();
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientFullNameChanged('Ahmad Ali'));
      await pumpEventQueue();
      expect(bloc.state.fullName, 'Ahmad Ali');

      bloc.add(const SignUpClientNationalIdChanged('1098765432'));
      await pumpEventQueue();
      expect(bloc.state.nationalId, '1098765432');

      bloc.add(const SignUpClientEmailChanged('ahmad@example.com'));
      await pumpEventQueue();
      expect(bloc.state.email, 'ahmad@example.com');

      bloc.add(const SignUpClientPhoneChanged('512345678'));
      await pumpEventQueue();
      expect(bloc.state.phone, '512345678');

      bloc.add(const SignUpClientTermsToggled(true));
      await pumpEventQueue();
      expect(bloc.state.termsAgreed, true);

      await bloc.close();
    });

    test(
      'shows validation errors when form is submitted empty or invalid',
      () async {
        final repo = FakeAuthRepository();
        final bloc = buildBloc(repo);

        bloc.add(const SignUpClientSubmitted());
        await pumpEventQueue();

        expect(bloc.state.fullNameError, 'validation.name_required');
        expect(bloc.state.nationalIdError, 'validation.national_id_required');
        expect(bloc.state.emailError, 'validation.email_required');
        expect(bloc.state.phoneError, 'validation.phone_required');
        expect(bloc.state.termsError, 'validation.terms_required');

        await bloc.close();
      },
    );

    test('shows error when email is already registered', () async {
      final repo = FakeAuthRepository(
        emailRegisteredResult: const Success(true),
      );
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientFullNameChanged('Ahmad Ali'));
      bloc.add(const SignUpClientNationalIdChanged('1098765432'));
      bloc.add(const SignUpClientEmailChanged('registered@example.com'));
      bloc.add(const SignUpClientPhoneChanged('512345678'));
      bloc.add(const SignUpClientTermsToggled(true));

      bloc.add(const SignUpClientSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, SignUpClientStatus.failure);
      expect(bloc.state.emailError, 'validation.email_already_registered');

      await bloc.close();
    });

    test('emits codeSent and step otp on successful submission', () async {
      final repo = FakeAuthRepository(
        emailRegisteredResult: const Success(false),
        sendOtpResult: const Success(null),
      );
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientFullNameChanged('Ahmad Ali'));
      bloc.add(const SignUpClientNationalIdChanged('1098765432'));
      bloc.add(const SignUpClientEmailChanged('new@example.com'));
      bloc.add(const SignUpClientPhoneChanged('512345678'));
      bloc.add(const SignUpClientTermsToggled(true));

      bloc.add(const SignUpClientSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, SignUpClientStatus.codeSent);
      expect(bloc.state.step, SignUpClientStep.otp);
      expect(bloc.state.resendSeconds, 30);

      await bloc.close();
    });

    test('handles failure when sending OTP fails', () async {
      final repo = FakeAuthRepository(
        emailRegisteredResult: const Success(false),
        sendOtpResult: const Failed(NetworkFailure()),
      );
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientFullNameChanged('Ahmad Ali'));
      bloc.add(const SignUpClientNationalIdChanged('1098765432'));
      bloc.add(const SignUpClientEmailChanged('new@example.com'));
      bloc.add(const SignUpClientPhoneChanged('512345678'));
      bloc.add(const SignUpClientTermsToggled(true));

      bloc.add(const SignUpClientSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, SignUpClientStatus.failure);
      expect(bloc.state.generalError, 'errors.network');

      await bloc.close();
    });

    test('handles OTP verification failure', () async {
      final repo = FakeAuthRepository(
        verifyOtpResult: const Failed(AuthFailure()),
      );
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientEmailChanged('test@example.com'));
      bloc.add(const SignUpClientOtpChanged('123456'));
      bloc.add(const SignUpClientOtpSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, SignUpClientStatus.failure);
      expect(bloc.state.otpError, 'errors.auth');

      await bloc.close();
    });

    test('handles full successful OTP verification and profile save', () async {
      final repo = FakeAuthRepository(
        verifyOtpResult: const Success(
          AuthSession(userId: 'uid-1', email: 'test@example.com'),
        ),
        saveProfileResult: const Success(null),
      );
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientFullNameChanged('Ahmad Ali'));
      bloc.add(const SignUpClientNationalIdChanged('1098765432'));
      bloc.add(const SignUpClientEmailChanged('test@example.com'));
      bloc.add(const SignUpClientPhoneChanged('512345678'));
      bloc.add(const SignUpClientOtpChanged('123456'));

      bloc.add(const SignUpClientOtpSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, SignUpClientStatus.success);
      expect(bloc.state.successMessage, 'auth.signup_success');

      await bloc.close();
    });

    test('handles step back from OTP to form', () async {
      final repo = FakeAuthRepository();
      final bloc = buildBloc(repo);

      bloc.add(const SignUpClientFullNameChanged('Ahmad Ali'));
      bloc.add(const SignUpClientNationalIdChanged('1098765432'));
      bloc.add(const SignUpClientEmailChanged('new@example.com'));
      bloc.add(const SignUpClientPhoneChanged('512345678'));
      bloc.add(const SignUpClientTermsToggled(true));
      bloc.add(const SignUpClientSubmitted());
      await pumpEventQueue();

      expect(bloc.state.step, SignUpClientStep.otp);

      bloc.add(const SignUpClientStepBack());
      await pumpEventQueue();

      expect(bloc.state.step, SignUpClientStep.form);
      expect(bloc.state.fullName, 'Ahmad Ali');

      await bloc.close();
    });
  });
}
