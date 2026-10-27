import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/dashboard/admin/datasource/models/admin_dashboard_stats_model.dart';

abstract interface class AdminDashboardRemoteDataSource {
  /// Throws PGRST116 (not found) for a user who isn't an admin.
  Future<AdminDashboardStatsModel> getStats();
}

class AdminDashboardRemoteDataSourceImpl
    implements AdminDashboardRemoteDataSource {
  const AdminDashboardRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AdminDashboardStatsModel> getStats() async {
    final row = await _client
        .from('v_admin_dashboard')
        .select(
          'active_users, clients, businesses, verified_businesses, projects, '
          'projects_draft, projects_open, projects_in_progress, '
          'projects_completed, projects_cancelled, market_items, '
          'market_items_live, pending_licenses, pending_deeds, open_reports, '
          'online_users',
        )
        .single();
    // The blockchain card: the same counts as the «البلوك تشين» tab.
    final blockchain = await _client
        .from('v_admin_blockchain_summary')
        .select('waiting, retrying, failed')
        .single();
    return AdminDashboardStatsModel.fromJson({
      ...row,
      for (final MapEntry(:key, :value) in blockchain.entries)
        'blockchain_$key': value,
    });
  }
}
