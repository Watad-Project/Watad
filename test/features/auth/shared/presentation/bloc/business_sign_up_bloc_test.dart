import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.emailRegisteredResult = const Success(false),
    this.saveResult = const Success(null),
  });

  Result<bool> emailRegisteredResult;
  Result<void> saveResult;

  @override
  Future<Result<void>> sendOtp({required String email}) async =>
      const Success(null);

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => const Success(AuthSession(userId: 'u', email: 'e'));

  @override
  Future<Result<bool>> isEmailRegistered(String email) async =>
      emailRegisteredResult;

  @override
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data) async =>
      saveResult;
}

BusinessSignUpBloc buildBloc(FakeAuthRepository repository) =>
    BusinessSignUpBloc(
      CheckEmailRegisteredUseCase(repository),
      SaveBusinessSignUpUseCase(repository),
    );

void main() {
  group('BusinessSignUpBloc', () {
    test('initial state has default values', () {
      final repository = FakeAuthRepository();
      final bloc = buildBloc(repository);
      expect(bloc.state.status, BusinessSignUpStatus.initial);
      expect(bloc.state.companyName, '');
      expect(bloc.state.crNumber, '');
      expect(bloc.state.email, '');
      expect(bloc.state.phone, '');
      expect(bloc.state.termsAgreed, false);
      expect(bloc.state.isSubmitting, false);
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
        ]),
      );

      bloc.add(const BusinessSignUpCompanyNameChanged('شركة وتد'));
      bloc.add(const BusinessSignUpCrNumberChanged('1010123456'));
      bloc.add(const BusinessSignUpEmailChanged('info@watad.sa'));
      bloc.add(const BusinessSignUpPhoneChanged('501234567'));
      bloc.add(const BusinessSignUpTermsToggled(true));

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

    test('emits inProgress then success on successful submission', () async {
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
            (s) => s.status == BusinessSignUpStatus.success,
          ),
        ]),
      );

      bloc.add(const BusinessSignUpSubmitted());
      await expectation;
      await bloc.close();
    });

    test('emits failure when email is already registered', () async {
      final repository = FakeAuthRepository(
        emailRegisteredResult: const Success(true),
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
                s.emailError == 'validation.email_already_registered',
          ),
        ]),
      );

      bloc.add(const BusinessSignUpSubmitted());
      await expectation;
      await bloc.close();
    });

    test('emits failure when server save fails', () async {
      final repository = FakeAuthRepository(
        saveResult: const Failed(ServerFailure()),
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
  });
}
