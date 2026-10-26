import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_bid_details_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_contract_project_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_work_overview_model.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';

abstract interface class ContractorWorkRemoteDataSource {
  Future<ContractorWorkOverviewModel> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  });

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
  Future<ContractorWorkOverviewModel> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  }) async {
    var query = _client
        .from('v_open_projects')
        .select(
          'id, title, description, budget, city, district, created_at, '
          'owner_name, owner_avatar_path, offer_count, my_offer_id, my_offer_amount, '
          'my_offer_status, is_mine',
        )
        .eq('is_mine', false);

    final trimmedCity = filter.city.trim();
    if (trimmedCity.isNotEmpty) {
      query = query.ilike('city', '%$trimmedCity%');
    }

    final trimmedDistrict = filter.district.trim();
    if (trimmedDistrict.isNotEmpty) {
      query = query.ilike('district', '%$trimmedDistrict%');
    }

    if (filter.minBudget case final minMoney?
        when minMoney > const Money.zero()) {
      query = query.gte('budget', minMoney.toJson());
    }

    if (filter.zeroOffersOnly) {
      query = query.eq('offer_count', 0);
    }

    final sanitizedSearch = filter.searchQuery
        .trim()
        .replaceAll(',', ' ')
        .replaceAll('%', '');
    if (sanitizedSearch.isNotEmpty) {
      query = query.or(
        'title.ilike.%$sanitizedSearch%,'
        'description.ilike.%$sanitizedSearch%,'
        'city.ilike.%$sanitizedSearch%,'
        'district.ilike.%$sanitizedSearch%',
      );
    }

    final List<dynamic> openProjectsResponse = switch (filter.sortBy) {
      ContractorWorkSortBy.highestBudget => await query.order(
        'budget',
        ascending: false,
        nullsFirst: false,
      ),
      ContractorWorkSortBy.nearestDistance =>
        await query
            .order('city', ascending: true)
            .order('created_at', ascending: false),
      ContractorWorkSortBy.newest => await query.order(
        'created_at',
        ascending: false,
      ),
    };

    final contractsPayload = await _fetchContractsAndTasks();

    final images = _client.storage.from('images');
    final avatars = _client.storage.from('avatars');
    final processedOpenProjects = [
      for (final row in openProjectsResponse)
        () {
          final map = Map<String, dynamic>.from(row as Map);
          if (map['image_url'] == null) {
            if (map['photo_paths'] case [final String first, ...]
                when first.isNotEmpty) {
              map['image_url'] = images.getPublicUrl(first);
            }
          }
          if (map['owner_avatar_url'] == null &&
              map['owner_avatar_path'] is String) {
            final path = (map['owner_avatar_path'] as String).trim();
            if (path.isNotEmpty) {
              map['owner_avatar_url'] = path.startsWith('http')
                  ? path
                  : avatars.getPublicUrl(path);
            }
          }
          return map;
        }(),
    ];

    return ContractorWorkOverviewModel.fromJson({
      'open_projects': processedOpenProjects,
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
          'owner_name, owner_avatar_path, offer_count, my_offer_id, my_offer_amount, '
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

    final images = _client.storage.from('images');
    final avatars = _client.storage.from('avatars');
    final processedProjectRow = projectRow != null
        ? () {
            final map = Map<String, dynamic>.from(projectRow);
            if (map['image_url'] == null) {
              if (map['photo_paths'] case [final String first, ...]
                  when first.isNotEmpty) {
                map['image_url'] = images.getPublicUrl(first);
              }
            }
            if (map['owner_avatar_url'] == null &&
                map['owner_avatar_path'] is String) {
              final path = (map['owner_avatar_path'] as String).trim();
              if (path.isNotEmpty) {
                map['owner_avatar_url'] = path.startsWith('http')
                    ? path
                    : avatars.getPublicUrl(path);
              }
            }
            return map;
          }()
        : null;

    return ContractorBidDetailsModel.fromJson({
      'project': processedProjectRow,
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
