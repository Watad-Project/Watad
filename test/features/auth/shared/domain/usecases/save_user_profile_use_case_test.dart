import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_user_profile_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.result);
  final Result<String> result;

  @override
  Future<Result<String>> saveProfile(SignUpProfile profile) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('returns success when user profile is saved', () async {
    final repo = FakeAuthRepository(const Success('created'));
    final useCase = SaveUserProfileUseCase(repo);

    final result = await useCase(
      const SignUpProfile(
        fullName: 'Client Name',
        nationalId: '1234567890',
        phone: '+966512345678',
        role: 'client',
      ),
    );

    expect(result, isA<Success<String>>());
  });
}
