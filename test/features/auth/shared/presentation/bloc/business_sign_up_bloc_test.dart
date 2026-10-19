import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.sendOtpResult = const Success(null),
    this.verifyOtpResult = const Success(AuthSession(userId: 'u', email: 'e')),
    this.saveResult = const Success(null),
  });

  Result<void> sendOtpResult;
  Result<AuthSession> verifyOtpResult;
  Result<void> saveResult;

  final List<String> sentTo = [];
  final List<(String, String)> verified = [];
  BusinessSignUp? savedBusiness;

  @override
  Future<Result<AuthSession?>> signUp({
    required String email,
    String? password,
    String? phone,
    Map<String, dynamic>? data,
  }) async => const Success(null);

  @override
  Future<Result<void>> sendOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    sentTo.add(email);
    return sendOtpResult;
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async {
    verified.add((email, token));
    return verifyOtpResult;
  }

  @override
  Future<Result<void>> sendSignUpOtp(String email) async =>
      sendOtp(email: email, shouldCreateUser: true);

  @override
  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params) async =>
      verifyOtpResult;

  @override
  Future<Result<String>> saveProfile(SignUpProfile profile) async =>
      const Success('created');

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data) async {
    savedBusiness = data;
    return saveResult;
  }
}

BusinessSignUpBloc buildBloc(FakeAuthRepository repository) =>
    BusinessSignUpBloc(
      SendSignUpOtpUseCase(repository),
      VerifyOtpUseCase(repository),
      SaveBusinessSignUpUseCase(repository),
    );

void main() {
  group('BusinessSignUpBloc', () {
    test('initial state has default values', () {
      final repository = FakeAuthRepository();
      final bloc = buildBloc(repository);
      expect(bloc.state.status, BusinessSignUpStatus.initial);
      expect(bloc.state.step, BusinessSignUpStep.form);
      expect(bloc.state.companyName, '');
      expect(bloc.state.crNumber, '');
      expect(bloc.state.email, '');
      expect(bloc.state.phone, '');
      expect(bloc.state.termsAgreed, false);
      expect(bloc.state.otp, '');
      expect(bloc.state.isSubmitting, false);
      expect(bloc.state.isOtpStep, false);
      bloc.close();
    });

    test('updates field values on change events', () async {
      final repository = FakeAuthRepository();
      final bloc = buildBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BusinessSignUpState>((s) => s.companyName == 'شركة وتد'),
          predicate<BusinessSignUpState>((s) => s.crNumber == '1010123456'),
          predicate<BusinessSignUpState>((s) => s.email == 'info@watad.sa'),
          predicate<BusinessSignUpState>((s) => s.phone == '501234567'),
          predicate<BusinessSignUpState>((s) => s.termsAgreed == true),
          predicate<BusinessSignUpState>((s) => s.otp == '123456'),
        ]),
      );

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));
      bloc.add(const BusinessSignUpOtpChanged('123456'));

      await expectation;
      await bloc.close();
    });

    test(
      'emits validation errors when submitting invalid empty fields',
      () async {
        final repository = FakeAuthRepository();
        final bloc = buildBloc(repository);

        final expectation = expectLater(
          bloc.stream,
          emits(
            predicate<BusinessSignUpState>(
              (s) =>
                  s.companyNameError != null &&
                  s.crNumberError != null &&
                  s.emailError != null &&
                  s.phoneError != null &&
                  s.termsError != null,
            ),
          ),
        );

        bloc.add(const BusinessSignUpSubmitted());
        await expectation;
        await bloc.close();
      },
    );

    test('emits inProgress then switches to OTP step on successful form submission', () async {
      final repository = FakeAuthRepository();
      final bloc = buildBloc(repository);

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));
      await Future<void>.delayed(Duration.zero);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BusinessSignUpState>(
            (s) => s.status == BusinessSignUpStatus.inProgress,
          ),
          predicate<BusinessSignUpState>(
            (s) =>
                s.step == BusinessSignUpStep.otp &&
                s.resendSeconds == BusinessSignUpBloc.resendCooldownSeconds &&
                s.isOtpStep == true,
          ),
        ]),
      );

      bloc.add(const BusinessSignUpSubmitted());
      await expectation;
      expect(repository.sentTo, contains('info@watad.sa'));
      await bloc.close();
    });

    test('emits failure when sending sign up OTP fails', () async {
      final repository = FakeAuthRepository(
        sendOtpResult: const Failed(ServerFailure()),
      );
      final bloc = buildBloc(repository);

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));
      await Future<void>.delayed(Duration.zero);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BusinessSignUpState>(
            (s) => s.status == BusinessSignUpStatus.inProgress,
          ),
          predicate<BusinessSignUpState>(
            (s) =>
                s.status == BusinessSignUpStatus.failure &&
                s.generalError == 'errors.server',
          ),
        ]),
      );

      bloc.add(const BusinessSignUpSubmitted());
      await expectation;
      await bloc.close();
    });

    test('emits failure and sets emailError when email is already registered, staying on form step', () async {
      final repository = FakeAuthRepository(
        sendOtpResult: const Failed(
          AuthFailure(null, 'auth.account_already_exists'),
        ),
      );
      final bloc = buildBloc(repository);

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('existing@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));
      await Future<void>.delayed(Duration.zero);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BusinessSignUpState>(
            (s) => s.status == BusinessSignUpStatus.inProgress,
          ),
          predicate<BusinessSignUpState>(
            (s) =>
                s.status == BusinessSignUpStatus.failure &&
                s.generalError == 'auth.account_already_exists' &&
                s.emailError == 'auth.account_already_exists' &&
                s.step == BusinessSignUpStep.form &&
                s.isOtpStep == false,
          ),
        ]),
      );

      bloc.add(const BusinessSignUpSubmitted());
      await expectation;
      await bloc.close();
    });

    test('emits otpError when submitting OTP with invalid length', () async {
      final repository = FakeAuthRepository();
      final bloc = buildBloc(repository);

      bloc.add(const BusinessSignUpOtpChanged('123'));
      await Future<void>.delayed(Duration.zero);

      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<BusinessSignUpState>(
            (s) => s.otpError == 'auth.invalid_otp_error',
          ),
        ),
      );

      bloc.add(const BusinessSignUpOtpSubmitted());
      await expectation;
      await bloc.close();
    });

    test(
      'verifies OTP, inserts business and emits success on valid OTP',
      () async {
        final repository = FakeAuthRepository();
        final bloc = buildBloc(repository);

        bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
        bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
        bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
        bloc.add(const BusinessSignUpPhoneChanged('501234567'));
        bloc.add(const BusinessSignUpTermsToggled(true));
        bloc.add(const BusinessSignUpOtpChanged('123456'));
        await Future<void>.delayed(Duration.zero);

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<BusinessSignUpState>(
              (s) => s.status == BusinessSignUpStatus.inProgress,
            ),
            predicate<BusinessSignUpState>(
              (s) => s.status == BusinessSignUpStatus.success,
            ),
          ]),
        );

        bloc.add(const BusinessSignUpOtpSubmitted());
        await expectation;

        expect(repository.verified, [('info@watad.sa', '123456')]);
        expect(repository.savedBusiness?.companyName, 'شركة وتد');
        expect(repository.savedBusiness?.crNumber, '1010123456');
        expect(repository.savedBusiness?.email, 'info@watad.sa');
        expect(repository.savedBusiness?.phone, '+966501234567');
        expect(repository.savedBusiness?.specializedField, 'contractor');
        expect(repository.savedBusiness?.role, 'contractor');
        await bloc.close();
      },
    );

    test('emits failure when OTP verification fails', () async {
      final repository = FakeAuthRepository(
        verifyOtpResult: const Failed(
          ValidationFailure('auth.otp_expired_or_invalid'),
        ),
      );
      final bloc = buildBloc(repository);

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));
      bloc.add(const BusinessSignUpOtpChanged('123456'));
      await Future<void>.delayed(Duration.zero);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BusinessSignUpState>(
            (s) => s.status == BusinessSignUpStatus.inProgress,
          ),
          predicate<BusinessSignUpState>(
            (s) =>
                s.status == BusinessSignUpStatus.failure &&
                s.otpError == 'auth.otp_expired_or_invalid',
          ),
        ]),
      );

      bloc.add(const BusinessSignUpOtpSubmitted());
      await expectation;
      expect(repository.savedBusiness, isNull);
      await bloc.close();
    });

    test(
      'emits failure when server save fails after OTP verification',
      () async {
        final repository = FakeAuthRepository(
          saveResult: const Failed(ServerFailure()),
        );
        final bloc = buildBloc(repository);

        bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
        bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
        bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
        bloc.add(const BusinessSignUpPhoneChanged('501234567'));
        bloc.add(const BusinessSignUpTermsToggled(true));
        bloc.add(const BusinessSignUpOtpChanged('123456'));
        await Future<void>.delayed(Duration.zero);

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<BusinessSignUpState>(
              (s) => s.status == BusinessSignUpStatus.inProgress,
            ),
            predicate<BusinessSignUpState>(
              (s) =>
                  s.status == BusinessSignUpStatus.failure &&
                  s.generalError == 'errors.server',
            ),
          ]),
        );

        bloc.add(const BusinessSignUpOtpSubmitted());
        await expectation;
        await bloc.close();
      },
    );

    test('step back from OTP transitions back to form step', () async {
      final repository = FakeAuthRepository();
      final bloc = buildBloc(repository);

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));
      bloc.add(const BusinessSignUpSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.step, BusinessSignUpStep.otp);

      bloc.add(const BusinessSignUpStepBack());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.step, BusinessSignUpStep.form);
      expect(bloc.state.companyName, 'شركة وتد');
      await bloc.close();
    });
  });
}
