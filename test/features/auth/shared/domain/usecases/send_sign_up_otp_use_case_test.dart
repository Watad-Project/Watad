import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SendSignUpOtpUseCase sendSignUpOtp;

  setUp(() {
    repository = FakeAuthRepository();
    sendSignUpOtp = SendSignUpOtpUseCase(repository);
  });

  Matcher validationFailure(String key) => isA<Failed<void>>().having(
    (result) => result.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'messageKey', key),
  );

  test('an empty email is required, and nothing is sent', () async {
    expect(
      await sendSignUpOtp('  '),
      validationFailure('auth.email_required_error'),
    );
    expect(repository.sentTo, isEmpty);
  });

  test('an invalid email is rejected, and nothing is sent', () async {
    expect(
      await sendSignUpOtp('not-an-email'),
      validationFailure('auth.invalid_email_error'),
    );
    expect(repository.sentTo, isEmpty);
  });

  test('a valid email sends a code with shouldCreateUser: true', () async {
    expect(await sendSignUpOtp(' user@watad.sa '), isA<Success<void>>());
    expect(repository.sentTo, ['user@watad.sa']);
    expect(repository.sentToWithCreateUser, [('user@watad.sa', true)]);
  });

  test("passes the repository's failure on", () async {
    repository.sendOtpResult = const Failed(RateLimitFailure());

    final result = await sendSignUpOtp('user@watad.sa');

    expect(
      result,
      isA<Failed<void>>().having(
        (r) => r.failure,
        'failure',
        isA<RateLimitFailure>(),
      ),
    );
  });
}
