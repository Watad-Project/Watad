import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_suspension.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_suspend_user_use_case.dart';

import '../../../../../helpers/fake_admin_users_repository.dart';

void main() {
  late FakeAdminUsersRepository repository;

  setUp(() => repository = FakeAdminUsersRepository());

  Future<Result<void>> suspend(AdminUser user, String reason) =>
      AdminSuspendUserUseCase(repository)(
        AdminUserSuspension(user: user, reason: reason),
      );

  Matcher refused(String key) => isA<Failed<void>>().having(
    (f) => f.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'key', key),
  );

  test('suspends with the trimmed reason', () async {
    final result = await suspend(fakeClient, '  رسائل مسيئة  ');

    expect(result, isA<Success<void>>());
    expect(repository.calls, ['suspend u-client: رسائل مسيئة']);
  });

  test('refuses what the database refuses, each with its message', () async {
    expect(await suspend(fakeClosed, 'سبب'), refused('users.error_closed'));
    expect(await suspend(fakeMe, 'سبب'), refused('users.error_suspend_self'));
    expect(
      await suspend(fakeAdmin, 'سبب'),
      refused('users.error_suspend_admin'),
    );
    expect(
      await suspend(fakeSuspended, 'سبب'),
      refused('users.error_already_suspended'),
    );
    expect(await suspend(fakeClient, '  '), refused('common.reason_required'));
    expect(
      await suspend(fakeClient, 'س' * 1001),
      refused('users.error_reason_too_long'),
    );
    expect(repository.calls, isEmpty);
  });
}
