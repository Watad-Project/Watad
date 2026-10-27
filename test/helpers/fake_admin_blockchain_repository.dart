import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/blockchain/admin/admin_blockchain_injection.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_job_result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_summary.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

/// A synced project and one that needs attention, like the live data.
final List<AdminBlockchainProject> fakeAdminBlockchainProjects = [
  AdminBlockchainProject(
    projectId: 'p-synced',
    title: 'فيلا سكنية',
    projectStatus: ProjectStatus.inProgress,
    syncStatus: AdminBlockchainSyncStatus.synced,
    version: 5,
    attempts: 0,
    ownerName: 'طه الحازمي',
    contractorName: 'مؤسسة الأساس الحديث',
    lastAttemptAt: DateTime.utc(2026, 10, 17, 5, 3),
    syncedAt: DateTime.utc(2026, 10, 17, 5, 3),
    lastMessage: 'already up to date',
  ),
  AdminBlockchainProject(
    projectId: 'p-failed',
    title: 'بناء ملحق',
    projectStatus: ProjectStatus.inProgress,
    syncStatus: AdminBlockchainSyncStatus.failed,
    version: 19,
    attempts: 0,
    contractorName: 'مقاولات الخبر',
    lastAttemptAt: DateTime.utc(2026, 10, 25, 21, 30),
    lastMessage:
        'project created was refused (400): project: "owner" is required '
        'and must be a non-empty string',
  ),
];

const AdminBlockchainSummary fakeAdminBlockchainSummary =
    AdminBlockchainSummary(
      projects: 2,
      synced: 1,
      waiting: 0,
      retrying: 0,
      failed: 1,
      retryJobActive: true,
      retryJobLastResult: AdminBlockchainJobResult.succeeded,
    );

/// A hand-written [AdminBlockchainRepository]: it answers with the results
/// you set and records every resync (APP_ARCHITECTURE.md §16).
class FakeAdminBlockchainRepository implements AdminBlockchainRepository {
  Result<AdminBlockchainOverview> overviewResult = Success(
    AdminBlockchainOverview(
      summary: fakeAdminBlockchainSummary,
      projects: fakeAdminBlockchainProjects,
    ),
  );

  Result<AdminBlockchainHealth> healthResult = Success(
    AdminBlockchainHealth(
      isReachable: true,
      checkedAt: DateTime.utc(2026, 10, 27, 8, 30),
      httpStatus: 200,
      latency: const Duration(milliseconds: 230),
    ),
  );

  /// Answers [getProject]: the project of [overviewResult] with that id,
  /// or [NotFoundFailure], unless set.
  Result<AdminBlockchainProject>? projectResult;

  Result<void> resyncResult = const Success(null);

  /// The projects resynced, in order.
  final List<String> resynced = [];

  /// How many times the ledger was checked.
  int healthChecks = 0;

  @override
  Future<Result<AdminBlockchainOverview>> getOverview() async => overviewResult;

  @override
  Future<Result<AdminBlockchainProject>> getProject(String projectId) async {
    if (projectResult case final result?) return result;
    final projects = switch (overviewResult) {
      Success(:final data) => data.projects,
      Failed() => const <AdminBlockchainProject>[],
    };
    for (final project in projects) {
      if (project.projectId == projectId) return Success(project);
    }
    return const Failed(NotFoundFailure());
  }

  @override
  Future<Result<AdminBlockchainHealth>> checkHealth() async {
    healthChecks++;
    return healthResult;
  }

  @override
  Future<Result<void>> resync(String projectId) async {
    resynced.add(projectId);
    return resyncResult;
  }
}

/// For tests that open the admin's navigation (its «البلوك تشين» tab) or
/// the blockchain routes: the real registrations, with [repository] in
/// place of Supabase. Reset getIt after the test.
void registerFakeAdminBlockchain(FakeAdminBlockchainRepository repository) {
  registerAdminBlockchainDependencies(getIt);
  getIt
    ..unregister<AdminBlockchainRepository>()
    ..registerSingleton<AdminBlockchainRepository>(repository);
}
