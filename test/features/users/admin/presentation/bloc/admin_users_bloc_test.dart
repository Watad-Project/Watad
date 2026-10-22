import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_count_users_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_get_users_use_case.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_users_bloc.dart';

import '../../../../../helpers/fake_admin_users_repository.dart';

void main() {
  late FakeAdminUsersRepository repository;

  AdminUsersBloc buildBloc() => AdminUsersBloc(
    AdminGetUsersUseCase(repository),
    AdminCountUsersUseCase(repository),
    searchDelay: Duration.zero,
  );

  Future<AdminUsersState> settled(AdminUsersBloc bloc) =>
      bloc.stream.firstWhere(
        (s) => s.status == AdminUsersStatus.success && s.counts != null,
      );

  setUp(() => repository = FakeAdminUsersRepository());

  test('loads the first page and the counts', () async {
    final bloc = buildBloc()..add(const AdminUsersFetched());

    final state = await settled(bloc);
    expect(state.users, hasLength(6));
    expect(state.hasMore, isFalse);
    expect(state.counts!.of(AdminUsersFilter.all), 6);
    expect(state.counts!.of(AdminUsersFilter.clients), 3);
    expect(state.counts!.of(AdminUsersFilter.businesses), 1);
    expect(state.counts!.of(AdminUsersFilter.admins), 2);
    expect(state.counts!.of(AdminUsersFilter.suspended), 1);
    await bloc.close();
  });

  test('a chip shows only its users', () async {
    final bloc = buildBloc()..add(const AdminUsersFetched());
    await settled(bloc);

    bloc.add(const AdminUsersFilterChanged(AdminUsersFilter.admins));
    final state = await bloc.stream.firstWhere(
      (s) =>
          s.status == AdminUsersStatus.success &&
          s.filter == AdminUsersFilter.admins,
    );
    expect(state.users, [fakeAdmin, fakeMe]);
    await bloc.close();
  });

  test('a search narrows the list and the counts', () async {
    final bloc = buildBloc()..add(const AdminUsersFetched());
    await settled(bloc);

    bloc.add(const AdminUsersSearchChanged(' الخبر '));
    final state = await bloc.stream.firstWhere(
      (s) =>
          s.status == AdminUsersStatus.success &&
          s.search == 'الخبر' &&
          s.counts!.of(AdminUsersFilter.all) == 1,
    );
    // Found by the company name.
    expect(state.users, [fakeBusiness]);
    expect(repository.queries.last.search, 'الخبر');
    await bloc.close();
  });

  test('the next page joins the list at the end', () async {
    repository.users = [
      for (var i = 0; i < AdminUsersBloc.pageSize + 5; i++)
        AdminUser(
          id: 'u-$i',
          name: 'مستخدم $i',
          role: UserRole.user,
          memberSince: DateTime.utc(2026, 10, 1),
        ),
    ];
    final bloc = buildBloc()..add(const AdminUsersFetched());
    final first = await settled(bloc);
    expect(first.users, hasLength(AdminUsersBloc.pageSize));
    expect(first.hasMore, isTrue);

    bloc.add(const AdminUsersMoreRequested());
    final more = await bloc.stream.firstWhere(
      (s) => !s.isLoadingMore && s.users.length > AdminUsersBloc.pageSize,
    );
    expect(more.users, hasLength(AdminUsersBloc.pageSize + 5));
    expect(more.hasMore, isFalse);
    expect(repository.queries.last.offset, AdminUsersBloc.pageSize);
    await bloc.close();
  });

  test('a failed first page says why', () async {
    repository.usersResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const AdminUsersFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminUsersStatus.failure,
    );
    expect(state.users, isEmpty);
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });
}
