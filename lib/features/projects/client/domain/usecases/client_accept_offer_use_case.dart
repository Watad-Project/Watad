import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// «قبول العرض».
class ClientAcceptOfferUseCase
    implements UseCase<void, ClientAcceptOfferParams> {
  const ClientAcceptOfferUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(ClientAcceptOfferParams params) =>
      _repository.acceptOffer(params);
}
