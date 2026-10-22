import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_unsuspend_user_use_case.dart';

import '../../../../../helpers/fake_admin_users_repository.dart';

void main() {
  test('lifts a suspension, and only that', () async {
    final repository = FakeAdminUsersRepository();
    final unsuspend = AdminUnsuspendUserUseCase(repository);

    expect(await unsuspend(fakeSuspended), isA<Success<void>>());
    final notSuspended = await unsuspend(fakeClient);
    expect(
      notSuspended,
      isA<Failed<void>>().having(
        (f) => f.failure.messageKey,
        'key',
        'users.error_not_suspended',
      ),
    );
    expect(
      await unsuspend(fakeClosed),
      isA<Failed<void>>().having(
        (f) => f.failure,
        'f',
        isA<ValidationFailure>(),
      ),
    );
    expect(repository.calls, ['unsuspend u-suspended']);
  });
}
