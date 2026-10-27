import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_health_model.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_project_model.dart';
import 'package:watad/features/blockchain/admin/datasource/models/admin_blockchain_summary_model.dart';

abstract interface class AdminBlockchainRemoteDataSource {
  /// Throws PGRST116 (not found) for a user who isn't an admin.
  Future<AdminBlockchainSummaryModel> getSummary();

  Future<List<AdminBlockchainProjectModel>> getProjects();

  /// Throws PGRST116 (not found) when [projectId] isn't a contracted
  /// project.
  Future<AdminBlockchainProjectModel> getProject(String projectId);

  Future<AdminBlockchainHealthModel> checkHealth();

  Future<void> resync(String projectId);
}

class AdminBlockchainRemoteDataSourceImpl
    implements AdminBlockchainRemoteDataSource {
  const AdminBlockchainRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _projectColumns =
      'project_id, project_title, project_status, owner_name, '
      'contractor_name, sync_status, version, attempts, last_attempt_at, '
      'next_attempt_at, synced_at, last_message';

  @override
  Future<AdminBlockchainSummaryModel> getSummary() async {
    final row = await _client
        .from('v_admin_blockchain_summary')
        .select(
          'projects, synced, waiting, retrying, failed, last_synced_at, '
          'retry_job_active, retry_job_last_run_at, retry_job_last_status',
        )
        .single();
    return AdminBlockchainSummaryModel.fromJson(row);
  }

  @override
  Future<List<AdminBlockchainProjectModel>> getProjects() async {
    final rows = await _client
        .from('v_admin_blockchain_sync')
        .select(_projectColumns)
        .order('last_attempt_at', ascending: false, nullsFirst: false);
    return rows.map(AdminBlockchainProjectModel.fromJson).toList();
  }

  @override
  Future<AdminBlockchainProjectModel> getProject(String projectId) async {
    final row = await _client
        .from('v_admin_blockchain_sync')
        .select(_projectColumns)
        .eq('project_id', projectId)
        .single();
    return AdminBlockchainProjectModel.fromJson(row);
  }

  @override
  Future<AdminBlockchainHealthModel> checkHealth() async {
    final response = await _client.functions.invoke(
      'blockchain-health',
      body: const <String, dynamic>{},
    );
    final data = response.data;
    return AdminBlockchainHealthModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  @override
  Future<void> resync(String projectId) async {
    await _client.rpc<void>(
      'admin_blockchain_resync',
      params: {'p_project_id': projectId},
    );
  }
}
