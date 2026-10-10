import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/email_otp.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late VerifyOtpUseCase verifyOtp;

  setUp(() {
    repository = FakeAuthRepository();
    verifyOtp = VerifyOtpUseCase(repository);
  });

  Future<Result<AuthSession>> check(String token) =>
      verifyOtp(EmailOtp(email: 'user@watad.sa', token: token));

  Matcher validationFailure(String key) => isA<Failed<AuthSession>>().having(
    (result) => result.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'messageKey', key),
  );

  test('Supabase email codes have 6 digits', () {
    expect(VerifyOtpUseCase.codeLength, 6);
  });

  test('an empty code is required, and nothing is checked', () async {
    expect(await check(''), validationFailure('auth.otp_required_error'));
    expect(repository.checked, isEmpty);
  });

  test('a short code or one with letters is rejected', () async {
    expect(await check('1234'), validationFailure('auth.invalid_otp_error'));
    expect(await check('12ab56'), validationFailure('auth.invalid_otp_error'));
    expect(repository.checked, isEmpty);
  });

  test('a whole code is checked and signs the user in', () async {
    final result = await verifyOtp(
      const EmailOtp(email: ' user@watad.sa ', token: ' 482910 '),
    );

    expect(
      result,
      isA<Success<AuthSession>>().having((s) => s.data.userId, 'id', 'user-1'),
    );
    expect(repository.checked, [('user@watad.sa', '482910')]);
  });
}
