import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_overview_use_case.dart';

import '../../../../../helpers/fake_admin_blockchain_repository.dart';

AdminBlockchainProject _project(
  String id,
  AdminBlockchainSyncStatus status, {
  DateTime? lastAttemptAt,
}) => AdminBlockchainProject(
  projectId: id,
  title: id,
  projectStatus: ProjectStatus.inProgress,
  syncStatus: status,
  version: 1,
  attempts: 0,
  lastAttemptAt: lastAttemptAt,
);

void main() {
  test('projects that need a person come first, the latest attempt first '
      'inside each state', () async {
    final repository = FakeAdminBlockchainRepository()
      ..overviewResult = Success(
        AdminBlockchainOverview(
          summary: fakeAdminBlockchainSummary,
          projects: [
            _project(
              'synced-old',
              AdminBlockchainSyncStatus.synced,
              lastAttemptAt: DateTime.utc(2026, 10, 1),
            ),
            _project('waiting-never', AdminBlockchainSyncStatus.waiting),
            _project(
              'synced-new',
              AdminBlockchainSyncStatus.synced,
              lastAttemptAt: DateTime.utc(2026, 10, 20),
            ),
            _project(
              'retrying',
              AdminBlockchainSyncStatus.retrying,
              lastAttemptAt: DateTime.utc(2026, 10, 25),
            ),
            _project(
              'waiting',
              AdminBlockchainSyncStatus.waiting,
              lastAttemptAt: DateTime.utc(2026, 10, 26),
            ),
            _project(
              'failed',
              AdminBlockchainSyncStatus.failed,
              lastAttemptAt: DateTime.utc(2026, 10, 2),
            ),
          ],
        ),
      );

    final result = await AdminGetBlockchainOverviewUseCase(repository)(
      const NoParams(),
    );

    final overview = (result as Success<AdminBlockchainOverview>).data;
    expect(overview.projects.map((project) => project.projectId), [
      'failed',
      'retrying',
      'waiting',
      'waiting-never',
      'synced-new',
      'synced-old',
    ]);
  });

  test('a failure passes through', () async {
    final repository = FakeAdminBlockchainRepository()
      ..overviewResult = const Failed(PermissionFailure());

    final result = await AdminGetBlockchainOverviewUseCase(repository)(
      const NoParams(),
    );

    expect(result, isA<Failed<AdminBlockchainOverview>>());
  });
}
