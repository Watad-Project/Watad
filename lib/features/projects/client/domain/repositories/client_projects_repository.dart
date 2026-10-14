import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

abstract interface class ClientProjectsRepository {
  Future<Result<List<ClientProject>>> getMyProjects();

  Future<Result<ClientProject>> getProjectById(String projectId);

  Future<Result<List<ClientProjectOffer>>> getProjectOffers(String projectId);

  Future<Result<void>> acceptOffer({
    required String offerId,
    required Money expectedAmount,
  });
}
