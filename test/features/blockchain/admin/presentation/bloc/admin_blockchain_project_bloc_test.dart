import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_project_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_resync_blockchain_project_use_case.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_project_bloc.dart';

import '../../../../../helpers/fake_admin_blockchain_repository.dart';

AdminBlockchainProjectBloc _bloc(FakeAdminBlockchainRepository repository) =>
    AdminBlockchainProjectBloc(
      AdminGetBlockchainProjectUseCase(repository),
      AdminResyncBlockchainProjectUseCase(repository),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads the project of the route', () async {
    final bloc = _bloc(FakeAdminBlockchainRepository())
      ..add(const AdminBlockchainProjectFetched('p-failed'));
    await _settle();

    expect(bloc.state.projectId, 'p-failed');
    expect(bloc.state.project!.title, 'بناء ملحق');
    expect(bloc.state.failure, isNull);
    await bloc.close();
  });

  test('a project that is not contracted is not found', () async {
    final bloc = _bloc(FakeAdminBlockchainRepository())
      ..add(const AdminBlockchainProjectFetched('p-unknown'));
    await _settle();

    expect(bloc.state.project, isNull);
    expect(bloc.state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('a resync is sent, then the project is read again', () async {
    final repository = FakeAdminBlockchainRepository();
    final bloc = _bloc(repository)
      ..add(const AdminBlockchainProjectFetched('p-failed'));
    await _settle();

    bloc.add(const AdminBlockchainProjectResynced());
    await _settle();

    expect(repository.resynced, ['p-failed']);
    expect(bloc.state.isBusy, isFalse);
    expect(bloc.state.message!.key, 'blockchain.admin.resync_sent');
    expect(bloc.state.message!.isError, isFalse);
    await bloc.close();
  });

  test('a refused resync shows its failure', () async {
    final repository = FakeAdminBlockchainRepository()
      ..resyncResult = const Failed(PermissionFailure());
    final bloc = _bloc(repository)
      ..add(const AdminBlockchainProjectFetched('p-failed'));
    await _settle();

    bloc.add(const AdminBlockchainProjectResynced());
    await _settle();

    expect(bloc.state.message!.key, 'errors.permission');
    expect(bloc.state.message!.isError, isTrue);
    expect(bloc.state.project, isNotNull);
    await bloc.close();
  });
}
