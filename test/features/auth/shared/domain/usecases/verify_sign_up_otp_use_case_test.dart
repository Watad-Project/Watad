import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_sign_up_otp_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.result);
  final Result<AuthSession> result;

  @override
  Future<Result<AuthSession>> verifySignUpOtp(VerifyOtpParams params) async =>
      result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('returns auth session when OTP is verified', () async {
    const session = AuthSession(userId: 'u1', email: 'user@example.com');
    final repo = FakeAuthRepository(const Success(session));
    final useCase = VerifySignUpOtpUseCase(repo);

    final result = await useCase(
      const VerifyOtpParams(email: 'user@example.com', token: '123456'),
    );

    expect(result, isA<Success<AuthSession>>());
    expect((result as Success<AuthSession>).data.userId, 'u1');
  });
}
