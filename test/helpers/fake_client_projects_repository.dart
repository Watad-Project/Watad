import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/client_projects_injection.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// A hand-written [ClientProjectsRepository]: it answers with the results
/// you set and records every accepted offer and every new deed
/// (APP_ARCHITECTURE.md §16).
class FakeClientProjectsRepository implements ClientProjectsRepository {
  Result<void> createProjectResult = const Success(null);
  Result<List<ClientSavedAddress>> savedAddressesResult = const Success([]);
  Result<ClientSavedAddress>? createAddressResult;
  Result<List<ClientProject>> projectsResult = const Success([]);
  Result<ClientProject>? projectResult;
  Result<List<ClientProjectOffer>> offersResult = const Success([]);
  Result<void> acceptResult = const Success(null);
  Result<void> replaceDeedResult = const Success(null);

  /// The offers accepted, as (offer id, expected amount in halalas).
  final List<(String, int)> accepted = [];

  /// The new deeds sent, as (project id, file path).
  final List<(String, String)> replacedDeeds = [];

  @override
  Future<Result<void>> createProject(ClientNewProject project) async =>
      createProjectResult;

  @override
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses() async =>
      savedAddressesResult;

  @override
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) async =>
      createAddressResult ??
      (throw StateError('Set createAddressResult first'));

  @override
  Future<Result<List<ClientProject>>> getMyProjects() async => projectsResult;

  @override
  Future<Result<ClientProject>> getProject(String projectId) async =>
      projectResult ?? (throw StateError('Set projectResult first'));

  @override
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId) async =>
      offersResult;

  @override
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params) async {
    accepted.add((params.offerId, params.expectedAmount.halalas));
    return acceptResult;
  }

  @override
  Future<Result<void>> replaceDeed(ClientReplaceDeedParams params) async {
    replacedDeeds.add((params.projectId, params.filePath));
    return replaceDeedResult;
  }
}

/// For tests that open the client's navigation (its «مشاريعي» tab) or the
/// projects routes: the real registrations, with [repository] in place of
/// Supabase. Reset getIt after the test.
void registerFakeClientProjects([FakeClientProjectsRepository? repository]) {
  registerClientProjectsDependencies(getIt);
  getIt
    ..unregister<ClientProjectsRepository>()
    ..registerSingleton<ClientProjectsRepository>(
      repository ?? FakeClientProjectsRepository(),
    );
}
