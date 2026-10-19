import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

abstract interface class ClientProjectsRepository {
  /// The client's projects, newest first.
  Future<Result<List<ClientProject>>> getMyProjects();

  Future<Result<ClientProject>> getProject(String projectId);

  /// The offers on a project, cheapest first.
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId);

  /// Accepts the offer: the other pending offers are rejected and the
  /// project starts with this contractor.
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params);
}
