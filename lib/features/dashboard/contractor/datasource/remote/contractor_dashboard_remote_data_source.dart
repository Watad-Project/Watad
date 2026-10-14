import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_data_model.dart';

abstract interface class ContractorDashboardRemoteDataSource {
  Future<ContractorDashboardDataModel> getDashboardData();
}

class ContractorDashboardRemoteDataSourceImpl
    implements ContractorDashboardRemoteDataSource {
  const ContractorDashboardRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ContractorDashboardDataModel> getDashboardData() async {
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

    final now = DateTime.now().toUtc();
    num thisMonthEarnings = 0;
    num pendingTransfers = 0;

    for (final payment in paymentsResponse) {
      final status = payment['status'] as String?;
      final amount = payment['amount'] as num? ?? 0;
      final paidAtStr = payment['paid_at'] as String?;

      if (status == 'paid' && paidAtStr != null) {
        final paidAt = DateTime.parse(paidAtStr).toUtc();
        if (paidAt.year == now.year && paidAt.month == now.month) {
          thisMonthEarnings += amount;
        }
      } else if (status == 'processing') {
        pendingTransfers += amount;
      }
    }

    // 3. Opportunities Count from open projects
    final openProjectsResponse = await _client
        .from('v_open_projects')
        .select('id, is_mine, my_offer_id')
        .eq('is_mine', false)
        .filter('my_offer_id', 'is', null);

    // 4. In Progress Projects
    final activeProjectsResponse = await _client
        .from('v_my_projects')
        .select(
          'id, title, status, client_name, my_role, budget, created_at, city',
        )
        .eq('my_role', 'taker')
        .eq('status', 'in_progress')
        .order('created_at', ascending: false);

    final projectIds = activeProjectsResponse
        .map((p) => p['id'] as String)
        .toList();

    // Tasks for active projects to calculate progress
    final tasksMap = <String, ({int approved, int total})>{};
    if (projectIds.isNotEmpty) {
      final tasksResponse = await _client
          .from('v_project_tasks')
          .select('id, project_id, status')
          .inFilter('project_id', projectIds);

      for (final task in tasksResponse) {
        final projectId = task['project_id'] as String;
        final taskStatus = task['status'] as String?;
        final current = tasksMap[projectId] ?? (approved: 0, total: 0);

        if (taskStatus != 'rejected') {
          final isApproved = taskStatus == 'approved';
          tasksMap[projectId] = (
            approved: current.approved + (isApproved ? 1 : 0),
            total: current.total + 1,
          );
        }
      }
    }

    final enrichedActiveProjects = activeProjectsResponse.map((p) {
      final id = p['id'] as String;
      final taskCounts = tasksMap[id] ?? (approved: 0, total: 0);
      return {
        ...p,
        'approved_tasks_count': taskCounts.approved,
        'total_tasks_count': taskCounts.total,
      };
    }).toList();

    // 5. My Offers
    final offersResponse = await _client
        .from('v_project_offers')
        .select(
          'id, project_id, project_title, amount, status, created_at, is_mine',
        )
        .eq('is_mine', true)
        .order('created_at', ascending: false);

    return ContractorDashboardDataModel.fromJson({
      'profile': profileResponse ?? {},
      'earnings': {
        'this_month_earnings': thisMonthEarnings,
        'pending_transfers': pendingTransfers,
      },
      'opportunities_count': openProjectsResponse.length,
      'active_projects': enrichedActiveProjects,
      'my_offers': offersResponse,
    });
  }
}
