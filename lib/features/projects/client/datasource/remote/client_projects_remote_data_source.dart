import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';

abstract interface class ClientProjectsRemoteDataSource {
  Future<List<ClientProjectModel>> getMyProjects();

  Future<ClientProjectModel> getProject(String projectId);

  Future<List<ClientProjectOfferModel>> getOffers(String projectId);

  Future<void> acceptOffer(String offerId, Money expectedAmount);
}

class ClientProjectsRemoteDataSourceImpl
    implements ClientProjectsRemoteDataSource {
  const ClientProjectsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _projectColumns =
      'id, title, status, city, district, budget, pending_offer_count, '
      'created_at';

  @override
  Future<List<ClientProjectModel>> getMyProjects() async {
    final rows = await _client
        .from('v_my_projects')
        .select(_projectColumns)
        .eq('my_role', 'owner')
        .order('created_at', ascending: false);
    return rows.map(ClientProjectModel.fromJson).toList();
  }

  @override
  Future<ClientProjectModel> getProject(String projectId) async {
    final row = await _client
        .from('v_my_projects')
        .select(_projectColumns)
        .eq('my_role', 'owner')
        .eq('id', projectId)
        .single();
    return ClientProjectModel.fromJson(row);
  }

  @override
  Future<List<ClientProjectOfferModel>> getOffers(String projectId) async {
    final rows = await _client
        .from('v_project_offers')
        .select(
          'id, project_id, amount, status, message, created_at, '
          'provider_company_name, provider_is_verified, provider_rating_avg, '
          'provider_rating_count',
        )
        .eq('project_id', projectId)
        // Cheapest first, as in the design.
        .order('amount', ascending: true);
    return rows.map(ClientProjectOfferModel.fromJson).toList();
  }

  @override
  Future<void> acceptOffer(String offerId, Money expectedAmount) async {
    await _client.rpc<void>(
      'accept_offer',
      params: {
        'p_offer_id': offerId,
        'p_expected_amount': expectedAmount.toJson(),
      },
    );
  }
}
