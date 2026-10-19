import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_bid_details_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_contract_project_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_work_overview_model.dart';

abstract interface class ContractorWorkRemoteDataSource {
  Future<ContractorWorkOverviewModel> getWorkOverview();

  Future<List<ContractorContractProjectModel>> getMyContracts();

  Future<ContractorBidDetailsModel> getBidDetails(String projectId);

  Future<void> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  });

  Future<void> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  });

  Future<void> withdrawOffer(String offerId);
}

class ContractorWorkRemoteDataSourceImpl
    implements ContractorWorkRemoteDataSource {
  const ContractorWorkRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ContractorWorkOverviewModel> getWorkOverview() async {
    final openProjectsResponse = await _client
        .from('v_open_projects')
        .select(
          'id, title, description, budget, city, district, created_at, '
          'owner_name, offer_count, my_offer_id, my_offer_amount, '
          'my_offer_status, is_mine',
        )
        .eq('is_mine', false)
        .order('created_at', ascending: false);

    final contractsPayload = await _fetchContractsAndTasks();

    return ContractorWorkOverviewModel.fromJson({
      'open_projects': openProjectsResponse,
      'contracts': contractsPayload.contracts,
      'tasks': contractsPayload.tasks,
      'contracts_count': contractsPayload.contracts.length,
    });
  }

  @override
  Future<List<ContractorContractProjectModel>> getMyContracts() async {
    final contractsPayload = await _fetchContractsAndTasks();
    final overview = ContractorWorkOverviewModel.fromJson({
      'open_projects': const <Map<String, dynamic>>[],
      'contracts': contractsPayload.contracts,
      'tasks': contractsPayload.tasks,
    });
    return overview.contracts
        .whereType<ContractorContractProjectModel>()
        .toList(growable: false);
  }

  Future<
    ({List<Map<String, dynamic>> contracts, List<Map<String, dynamic>> tasks})
  >
  _fetchContractsAndTasks() async {
    final contractsResponse = await _client
        .from('v_my_projects')
        .select(
          'id, title, description, status, budget, agreed_amount, '
          'total_paid, city, district, owner_name, created_at, '
          'completed_at, my_role',
        )
        .eq('my_role', 'taker')
        .inFilter('status', ['in_progress', 'completed'])
        .order('created_at', ascending: false);

    final contracts = List<Map<String, dynamic>>.from(contractsResponse);
    final projectIds = contracts
        .map((row) => row['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final List<Map<String, dynamic>> tasks;
    if (projectIds.isNotEmpty) {
      final tasksResponse = await _client
          .from('v_project_tasks')
          .select('id, project_id, status')
          .inFilter('project_id', projectIds);
      tasks = List<Map<String, dynamic>>.from(tasksResponse);
    } else {
      tasks = const [];
    }

    return (contracts: contracts, tasks: tasks);
  }

  @override
  Future<ContractorBidDetailsModel> getBidDetails(String projectId) async {
    final projectRow = await _client
        .from('v_open_projects')
        .select(
          'id, title, description, budget, city, district, created_at, '
          'owner_name, offer_count, my_offer_id, my_offer_amount, '
          'my_offer_status, is_mine',
        )
        .eq('id', projectId)
        .maybeSingle();

    final profileRow = await _client
        .from('v_my_profile')
        .select('verification_status')
        .maybeSingle();

    final offerRow = await _client
        .from('v_project_offers')
        .select('id, amount, message, status, is_mine')
        .eq('project_id', projectId)
        .eq('is_mine', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return ContractorBidDetailsModel.fromJson({
      'project': projectRow,
      'verification_status': profileRow?['verification_status'] ?? 'unverified',
      'offer': offerRow,
    });
  }

  @override
  Future<void> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  }) async {
    await _client.from('project_offers').insert({
      'project_id': projectId,
      'amount': amount.toJson(),
      'message': message,
    });
  }

  @override
  Future<void> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  }) async {
    await _client
        .from('project_offers')
        .update({'amount': amount.toJson(), 'message': message})
        .eq('id', offerId);
  }

  @override
  Future<void> withdrawOffer(String offerId) async {
    await _client.rpc<void>('withdraw_offer', params: {'p_offer_id': offerId});
  }
}
