import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';

abstract interface class ClientProjectsRepository {
  Future<Result<void>> createProject(ClientNewProject project);
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses();
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  });

  /// The client's projects, newest first.
  Future<Result<List<ClientProject>>> getMyProjects();

  Future<Result<ClientProject>> getProject(String projectId);

  /// The offers on a project, cheapest first.
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId);

  /// Accepts the offer: the other pending offers are rejected and the
  /// project starts with this contractor.
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params);

  /// Uploads a new ownership deed for a project whose deed was rejected:
  /// it goes back to review.
  Future<Result<void>> replaceDeed(ClientReplaceDeedParams params);
}
