import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientProjectsRepositoryImpl implements ClientProjectsRepository {
  const ClientProjectsRepositoryImpl(this._remote);

  final ClientProjectsRemoteDataSource _remote;

  @override
  Future<Result<List<ClientProject>>> getMyProjects() =>
      guardSupabaseCall(_remote.getMyProjects);

  @override
  Future<Result<ClientProject>> getProject(String projectId) =>
      guardSupabaseCall(() => _remote.getProject(projectId));

  @override
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId) =>
      guardSupabaseCall(() => _remote.getOffers(projectId));

  @override
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params) =>
      guardSupabaseCall(
        () => _remote.acceptOffer(params.offerId, params.expectedAmount),
      );
}
