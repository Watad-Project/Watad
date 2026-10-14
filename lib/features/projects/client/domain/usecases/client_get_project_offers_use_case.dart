import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientGetProjectOffersUseCase
    implements UseCase<List<ClientProjectOffer>, String> {
  const ClientGetProjectOffersUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<List<ClientProjectOffer>>> call(String params) =>
      _repository.getProjectOffers(params);
}
