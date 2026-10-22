import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/dashboard/admin/domain/usecases/admin_get_dashboard_stats_use_case.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';

import '../../../../../helpers/fake_admin_dashboard_repository.dart';

void main() {
  late FakeAdminDashboardRepository repository;

  AdminDashboardBloc buildBloc() =>
      AdminDashboardBloc(AdminGetDashboardStatsUseCase(repository));

  setUp(() => repository = FakeAdminDashboardRepository());

  test('loads the numbers', () async {
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminDashboardState>().having(
          (s) => s.status,
          'status',
          AdminDashboardStatus.loading,
        ),
        isA<AdminDashboardState>()
            .having((s) => s.status, 'status', AdminDashboardStatus.success)
            .having((s) => s.stats, 'stats', fakeAdminDashboardStats),
      ]),
    );
    bloc.add(const AdminDashboardFetched());
    await states;
    await bloc.close();
  });

  test('a failed first read has no numbers and says why', () async {
    repository.statsResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const AdminDashboardFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminDashboardStatus.failure,
    );
    expect(state.stats, isNull);
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a failed reload keeps the last numbers on screen', () async {
    final bloc = buildBloc()..add(const AdminDashboardFetched());
    await bloc.stream.firstWhere(
      (s) => s.status == AdminDashboardStatus.success,
    );

    repository.statsResult = const Failed(NetworkFailure());
    bloc.add(const AdminDashboardFetched());
    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminDashboardStatus.failure,
    );
    expect(state.stats, fakeAdminDashboardStats);
    await bloc.close();
  });
}
