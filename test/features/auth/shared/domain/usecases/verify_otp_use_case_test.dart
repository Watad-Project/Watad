import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  Result<AuthSession> verifyOtpResult = const Success(
    AuthSession(userId: 'test-user'),
  );

  @override
  Future<Result<void>> sendOtp({required String email}) async =>
      const Success(null);

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => verifyOtpResult;
}

void main() {
  late FakeAuthRepository repository;
  late VerifyOtpUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = VerifyOtpUseCase(repository);
  });

  test('returns ValidationFailure when email is empty', () async {
    final result = await useCase(
      const VerifyOtpParams(email: '', token: '1234'),
    );
    expect(result, isA<Failed<AuthSession>>());
    final failure = (result as Failed<AuthSession>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'auth.email_required_error');
  });

  test('returns ValidationFailure when OTP is empty', () async {
    final result = await useCase(
      const VerifyOtpParams(email: 'user@example.com', token: ''),
    );
    expect(result, isA<Failed<AuthSession>>());
    final failure = (result as Failed<AuthSession>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'auth.otp_required_error');
  });

  test('returns ValidationFailure when OTP length is less than 4', () async {
    final result = await useCase(
      const VerifyOtpParams(email: 'user@example.com', token: '12'),
    );
    expect(result, isA<Failed<AuthSession>>());
    final failure = (result as Failed<AuthSession>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'auth.invalid_otp_error');
  });

  test('calls repository on valid inputs and returns AuthSession', () async {
    final result = await useCase(
      const VerifyOtpParams(email: 'user@example.com', token: '1234'),
    );
    expect(result, isA<Success<AuthSession>>());
    expect((result as Success<AuthSession>).data.userId, 'test-user');
  });
}
