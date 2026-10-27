import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_filter.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overall.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_check_blockchain_health_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_overview_use_case.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_bloc.dart';

import '../../../../../helpers/fake_admin_blockchain_repository.dart';

AdminBlockchainBloc _bloc(FakeAdminBlockchainRepository repository) =>
    AdminBlockchainBloc(
      AdminGetBlockchainOverviewUseCase(repository),
      AdminCheckBlockchainHealthUseCase(repository),
    );

/// Lets the bloc finish the events sent so far.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads the projects, those that need attention first, and checks '
      'the ledger', () async {
    final repository = FakeAdminBlockchainRepository();
    final bloc = _bloc(repository)..add(const AdminBlockchainFetched());
    await _settle();

    final state = bloc.state;
    expect(state.status, AdminBlockchainStatus.success);
    expect(state.overview!.projects.first.projectId, 'p-failed');
    expect(state.healthStatus, AdminBlockchainHealthStatus.success);
    expect(state.health!.isReachable, isTrue);
    expect(repository.healthChecks, 1);
    // A project needs attention.
    expect(state.overall, AdminBlockchainOverall.attention);
    await bloc.close();
  });

  test('a failed load keeps the failure', () async {
    final repository = FakeAdminBlockchainRepository()
      ..overviewResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)..add(const AdminBlockchainFetched());
    await _settle();

    expect(bloc.state.status, AdminBlockchainStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
    expect(bloc.state.overview, isNull);
    await bloc.close();
  });

  test('a check that cannot run is kept apart from the projects', () async {
    final repository = FakeAdminBlockchainRepository()
      ..healthResult = const Failed(PermissionFailure());
    final bloc = _bloc(repository)..add(const AdminBlockchainFetched());
    await _settle();

    expect(bloc.state.status, AdminBlockchainStatus.success);
    expect(bloc.state.healthStatus, AdminBlockchainHealthStatus.failure);
    expect(bloc.state.healthFailure, isA<PermissionFailure>());
    expect(bloc.state.health, isNull);
    await bloc.close();
  });

  test('«فحص الآن» checks the ledger again', () async {
    final repository = FakeAdminBlockchainRepository();
    final bloc = _bloc(repository)..add(const AdminBlockchainFetched());
    await _settle();

    bloc.add(const AdminBlockchainHealthChecked());
    await _settle();

    expect(repository.healthChecks, 2);
    await bloc.close();
  });

  test('a chip shows its projects and every chip has its count', () async {
    final bloc = _bloc(FakeAdminBlockchainRepository())
      ..add(const AdminBlockchainFetched());
    await _settle();

    bloc.add(const AdminBlockchainFilterChanged(AdminBlockchainFilter.synced));
    await _settle();

    expect(bloc.state.visibleProjects.map((p) => p.projectId), ['p-synced']);
    expect(bloc.state.countOf(AdminBlockchainFilter.all), 2);
    expect(bloc.state.countOf(AdminBlockchainFilter.failed), 1);
    expect(bloc.state.countOf(AdminBlockchainFilter.waiting), 0);
    await bloc.close();
  });
}
