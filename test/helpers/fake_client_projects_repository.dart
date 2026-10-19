import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/client_projects_injection.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// A hand-written [ClientProjectsRepository]: it answers with the results
/// you set and records every accepted offer (APP_ARCHITECTURE.md §16).
class FakeClientProjectsRepository implements ClientProjectsRepository {
  Result<List<ClientProject>> projectsResult = const Success([]);
  Result<ClientProject>? projectResult;
  Result<List<ClientProjectOffer>> offersResult = const Success([]);
  Result<void> acceptResult = const Success(null);

  /// The offers accepted, as (offer id, expected amount in halalas).
  final List<(String, int)> accepted = [];

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
