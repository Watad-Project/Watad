import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.result);
  final Result<void> result;

  @override
  Future<Result<void>> sendSignUpOtp(String email) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('returns success when OTP is sent', () async {
    final repo = FakeAuthRepository(const Success(null));
    final useCase = SendSignUpOtpUseCase(repo);

    final result = await useCase('user@example.com');

    expect(result, isA<Success<void>>());
  });
}
