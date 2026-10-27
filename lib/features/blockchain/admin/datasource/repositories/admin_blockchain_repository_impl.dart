import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/blockchain/admin/datasource/remote/admin_blockchain_remote_data_source.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';

class AdminBlockchainRepositoryImpl implements AdminBlockchainRepository {
  const AdminBlockchainRepositoryImpl(this._remote);

  final AdminBlockchainRemoteDataSource _remote;

  @override
  Future<Result<AdminBlockchainOverview>> getOverview() =>
      // One after the other, so a failure reaches guardSupabaseCall as the
      // Supabase error itself (a parallel wait would wrap it).
      guardSupabaseCall(
        () async => AdminBlockchainOverview(
          summary: await _remote.getSummary(),
          projects: await _remote.getProjects(),
        ),
      );

  @override
  Future<Result<AdminBlockchainProject>> getProject(String projectId) =>
      guardSupabaseCall(() => _remote.getProject(projectId));

  @override
  Future<Result<AdminBlockchainHealth>> checkHealth() =>
      guardSupabaseCall(_remote.checkHealth);

  @override
  Future<Result<void>> resync(String projectId) =>
      guardSupabaseCall(() => _remote.resync(projectId));
}
