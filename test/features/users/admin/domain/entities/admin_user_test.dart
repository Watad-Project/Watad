import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';

import '../../../../../helpers/fake_admin_users_repository.dart';

void main() {
  test('only the actions that can apply are offered', () {
    expect(fakeClient.canBeSuspended, isTrue);
    expect(fakeClient.canChangeRole, isTrue);
    // An admin loses the role before being suspended.
    expect(fakeAdmin.canBeSuspended, isFalse);
    expect(fakeAdmin.canChangeRole, isTrue);
    // Not yourself, not your own role.
    expect(fakeMe.canBeSuspended, isFalse);
    expect(fakeMe.canChangeRole, isFalse);
    expect(fakeSuspended.canBeSuspended, isFalse);
    expect(fakeSuspended.canBeUnsuspended, isTrue);
    // A closed account can't change.
    expect(fakeClosed.canBeSuspended, isFalse);
    expect(fakeClosed.canChangeRole, isFalse);
  });

  test('each chip takes its users', () {
    expect(AdminUsersFilter.clients.matches(fakeClient), isTrue);
    expect(AdminUsersFilter.clients.matches(fakeBusiness), isFalse);
    expect(AdminUsersFilter.clients.matches(fakeAdmin), isFalse);
    expect(AdminUsersFilter.contractors.matches(fakeBusiness), isTrue);
    expect(AdminUsersFilter.admins.matches(fakeMe), isTrue);
    expect(AdminUsersFilter.suspended.matches(fakeSuspended), isTrue);
    expect(AdminUsersFilter.suspended.matches(fakeClient), isFalse);
  });
}
