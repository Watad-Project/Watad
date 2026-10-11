import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.result);
  final Result<bool> result;

  @override
  Future<Result<bool>> isEmailRegistered(String email) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('returns email registration check result', () async {
    final repo = FakeAuthRepository(const Success(true));
    final useCase = CheckEmailRegisteredUseCase(repo);

    final result = await useCase('user@example.com');

    expect(result, isA<Success<bool>>());
    expect((result as Success<bool>).data, isTrue);
  });
}
