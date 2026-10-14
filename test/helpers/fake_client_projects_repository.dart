import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class FakeClientProjectsRepository implements ClientProjectsRepository {
  FakeClientProjectsRepository({
    this.projectsResult,
    this.projectResult,
    this.offersResult,
    this.acceptOfferResult = const Success(null),
  });

  Result<List<ClientProject>>? projectsResult;
  Result<ClientProject>? projectResult;
  Result<List<ClientProjectOffer>>? offersResult;
  Result<void> acceptOfferResult;

  String? lastAcceptedOfferId;
  Money? lastAcceptedExpectedAmount;

  @override
  Future<Result<List<ClientProject>>> getMyProjects() async =>
      projectsResult ?? const Success<List<ClientProject>>([]);

  @override
  Future<Result<ClientProject>> getProjectById(String projectId) async =>
      projectResult ?? const Failed(NotFoundFailure('errors.not_found'));

  @override
  Future<Result<List<ClientProjectOffer>>> getProjectOffers(
    String projectId,
  ) async => offersResult ?? const Success<List<ClientProjectOffer>>([]);

  @override
  Future<Result<void>> acceptOffer({
    required String offerId,
    required Money expectedAmount,
  }) async {
    lastAcceptedOfferId = offerId;
    lastAcceptedExpectedAmount = expectedAmount;
    return acceptOfferResult;
  }
}
