import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_get_user_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_set_user_role_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_suspend_user_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_unsuspend_user_use_case.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_user_details_bloc.dart';

import '../../../../../helpers/fake_admin_users_repository.dart';

void main() {
  late FakeAdminUsersRepository repository;

  AdminUserDetailsBloc buildBloc() => AdminUserDetailsBloc(
    AdminGetUserUseCase(repository),
    AdminSuspendUserUseCase(repository),
    AdminUnsuspendUserUseCase(repository),
    AdminSetUserRoleUseCase(repository),
  );

  Future<AdminUserDetailsBloc> loaded(String userId) async {
    final bloc = buildBloc()..add(AdminUserDetailsFetched(userId));
    await bloc.stream.firstWhere(
      (s) => s.status == AdminUserDetailsStatus.success,
    );
    return bloc;
  }

  setUp(() => repository = FakeAdminUsersRepository());

  test('loads the user', () async {
    final bloc = await loaded('u-client');
    expect(bloc.state.user, fakeClient);
    await bloc.close();
  });

  test('a user that does not exist is not found', () async {
    final bloc = buildBloc()..add(const AdminUserDetailsFetched('u-none'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminUserDetailsStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('suspending sends the reason and reads the user again', () async {
    final bloc = await loaded('u-client');
    final reads = repository.userReads;

    bloc.add(const AdminUserSuspended('رسائل مسيئة'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls, ['suspend u-client: رسائل مسيئة']);
    expect(repository.userReads, reads + 1);
    expect(state.isBusy, isFalse);
    expect(state.message?.key, 'users.suspended_done');
    await bloc.close();
  });

  test('lifting and the role changes say which one happened', () async {
    final suspended = await loaded('u-suspended');
    suspended.add(const AdminUserUnsuspended());
    final lifted = await suspended.stream.firstWhere((s) => s.message != null);
    expect(lifted.message?.key, 'users.unsuspended_done');
    await suspended.close();

    final client = await loaded('u-client');
    client.add(const AdminUserRoleChanged(UserRole.admin));
    final made = await client.stream.firstWhere((s) => s.message != null);
    expect(made.message?.key, 'users.made_admin_done');
    await client.close();

    expect(repository.calls, ['unsuspend u-suspended', 'role u-client admin']);
  });

  test('a refusal shows its own message and sends nothing', () async {
    final bloc = await loaded('u-admin');

    bloc.add(const AdminUserSuspended('سبب'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'users.error_suspend_admin');
    expect(state.message?.isError, isTrue);
    expect(repository.calls, isEmpty);
    await bloc.close();
  });

  test('a failed action keeps the user on screen', () async {
    final bloc = await loaded('u-client');
    repository.actionResult = const Failed(NetworkFailure());

    bloc.add(const AdminUserRoleChanged(UserRole.admin));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.user, fakeClient);
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });
}
