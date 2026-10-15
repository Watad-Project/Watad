import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';

abstract interface class ClientProjectsRemoteDataSource {
  Future<List<ClientProjectModel>> getMyProjects();

  Future<ClientProjectModel> getProjectById(String projectId);

  Future<List<ClientProjectOfferModel>> getProjectOffers(String projectId);

  Future<void> acceptOffer(String offerId, Money expectedAmount);
}

class ClientProjectsRemoteDataSourceImpl
    implements ClientProjectsRemoteDataSource {
  const ClientProjectsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ClientProjectModel>> getMyProjects() async {
    final rows = await _client
        .from('v_my_projects')
        .select(
          'id, title, status, city, district, budget, pending_offer_count, '
          'created_at',
        )
        .eq('my_role', 'owner')
        .order('created_at', ascending: false);
    return rows.map(ClientProjectModel.fromJson).toList();
  }

  @override
  Future<ClientProjectModel> getProjectById(String projectId) async {
    final row = await _client
        .from('v_my_projects')
        .select(
          'id, title, status, city, district, budget, pending_offer_count, '
          'created_at',
        )
        .eq('my_role', 'owner')
        .eq('id', projectId)
        .single();
    return ClientProjectModel.fromJson(row);
  }

  @override
  Future<List<ClientProjectOfferModel>> getProjectOffers(
    String projectId,
  ) async {
    final rows = await _client
        .from('v_project_offers')
        .select(
          'id, project_id, amount, status, created_at, contractor_name, '
          'contractor_rating, is_contractor_verified, duration_months, message',
        )
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
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
