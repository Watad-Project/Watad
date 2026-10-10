import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SendOtpUseCase sendOtp;

  setUp(() {
    repository = FakeAuthRepository();
    sendOtp = SendOtpUseCase(repository);
  });

  Matcher validationFailure(String key) => isA<Failed<void>>().having(
    (result) => result.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'messageKey', key),
  );

  test('an empty email is required, and nothing is sent', () async {
    expect(await sendOtp('  '), validationFailure('auth.email_required_error'));
    expect(repository.sentTo, isEmpty);
  });

  test('an invalid email is rejected, and nothing is sent', () async {
    expect(
      await sendOtp('not-an-email'),
      validationFailure('auth.invalid_email_error'),
    );
    expect(repository.sentTo, isEmpty);
  });

  test('a valid email gets a code, without the spaces around it', () async {
    expect(await sendOtp(' user@watad.sa '), isA<Success<void>>());
    expect(repository.sentTo, ['user@watad.sa']);
  });

  test("passes the repository's failure on", () async {
    repository.sendOtpResult = const Failed(RateLimitFailure());

    final result = await sendOtp('user@watad.sa');

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
