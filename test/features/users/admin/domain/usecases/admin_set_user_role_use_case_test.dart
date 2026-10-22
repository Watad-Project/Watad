import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user_role_change.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_set_user_role_use_case.dart';

import '../../../../../helpers/fake_admin_users_repository.dart';

void main() {
  test('makes an admin and removes the role', () async {
    final repository = FakeAdminUsersRepository();
    final setRole = AdminSetUserRoleUseCase(repository);

    await setRole(AdminUserRoleChange(user: fakeClient, role: UserRole.admin));
    await setRole(AdminUserRoleChange(user: fakeAdmin, role: UserRole.user));

    expect(repository.calls, ['role u-client admin', 'role u-admin user']);
  });

  test(
    "an admin can't remove their own role, nor change a closed account",
    () async {
      final repository = FakeAdminUsersRepository();
      final setRole = AdminSetUserRoleUseCase(repository);

      final own = await setRole(
        AdminUserRoleChange(user: fakeMe, role: UserRole.user),
      );
      final closed = await setRole(
        AdminUserRoleChange(user: fakeClosed, role: UserRole.admin),
      );

      expect(
        own,
        isA<Failed<void>>().having(
          (f) => f.failure.messageKey,
          'key',
          'users.error_remove_own_admin',
        ),
      );
      expect(
        closed,
        isA<Failed<void>>().having(
          (f) => f.failure.messageKey,
          'key',
          'users.error_closed',
        ),
      );
      expect(repository.calls, isEmpty);
    },
  );
}
