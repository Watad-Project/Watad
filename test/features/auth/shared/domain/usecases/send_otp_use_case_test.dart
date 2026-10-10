import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  Result<void> sendOtpResult = const Success(null);

  @override
  Future<Result<void>> sendOtp({required String email}) async => sendOtpResult;

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => const Success(AuthSession(userId: 'test'));
}

void main() {
  late FakeAuthRepository repository;
  late SendOtpUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = SendOtpUseCase(repository);
  });

  test('returns ValidationFailure when email is empty', () async {
    final result = await useCase('');
    expect(result, isA<Failed<void>>());
    final failure = (result as Failed<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'auth.email_required_error');
  });

  test('returns ValidationFailure when email format is invalid', () async {
    final result = await useCase('invalid-email');
    expect(result, isA<Failed<void>>());
    final failure = (result as Failed<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'auth.invalid_email_error');
  });

  test('calls repository when email is valid', () async {
    final result = await useCase('valid@example.com');
    expect(result, isA<Success<void>>());
  });
}
