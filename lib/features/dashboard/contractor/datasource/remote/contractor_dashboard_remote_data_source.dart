import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_raw_data_model.dart';

abstract interface class ContractorDashboardRemoteDataSource {
  Future<ContractorDashboardRawDataModel> getDashboardRawData();
}

class ContractorDashboardRemoteDataSourceImpl
    implements ContractorDashboardRemoteDataSource {
  const ContractorDashboardRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ContractorDashboardRawDataModel> getDashboardRawData() async {
    // 1. Profile & Verification
    final profileResponse = await _client
        .from('v_my_profile')
        .select('company_name, verification_status')
        .maybeSingle();

    // 2. Earnings from project payments
    final paymentsResponse = await _client
        .from('v_project_payments')
        .select('amount, status, paid_at, my_role')
        .eq('my_role', 'payee');

    // 3. Opportunities Count from open projects
    final openProjectsResponse = await _client
        .from('v_open_projects')
        .select('id, is_mine, my_offer_id')
        .eq('is_mine', false)
        .filter('my_offer_id', 'is', null);

    // 4. In Progress Projects (selecting owner_name, NOT client_name)
    final activeProjectsResponse = await _client
        .from('v_my_projects')
        .select(
          'id, title, status, owner_name, my_role, budget, created_at, city',
        )
        .eq('my_role', 'taker')
        .eq('status', 'in_progress')
        .order('created_at', ascending: false);

    final projectIds = activeProjectsResponse
        .map((p) => p['id'] as String)
        .toList();

    // 5. Tasks for active projects
    final List<Map<String, dynamic>> tasksResponse;
    if (projectIds.isNotEmpty) {
      final res = await _client
          .from('v_project_tasks')
          .select('id, project_id, status')
          .inFilter('project_id', projectIds);
      tasksResponse = List<Map<String, dynamic>>.from(res);
    } else {
      tasksResponse = [];
    }

    // 6. My Offers (v_project_offers has: id, project_id, project_title, amount, status, created_at, is_mine)
    final offersResponse = await _client
        .from('v_project_offers')
        .select(
          'id, project_id, project_title, amount, status, created_at, is_mine',
        )
        .eq('is_mine', true)
        .order('created_at', ascending: false);

    return ContractorDashboardRawDataModel.fromJson({
      'profile': profileResponse ?? {},
      'payments': paymentsResponse,
      'opportunities_count': openProjectsResponse.length,
      'projects': activeProjectsResponse,
      'tasks': tasksResponse,
      'offers': offersResponse,
    });
  }
}
