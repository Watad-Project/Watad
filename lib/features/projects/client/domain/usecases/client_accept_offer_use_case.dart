import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

typedef ClientAcceptOfferParams = ({String offerId, Money expectedAmount});

class ClientAcceptOfferUseCase
    implements UseCase<void, ClientAcceptOfferParams> {
  const ClientAcceptOfferUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(ClientAcceptOfferParams params) =>
      _repository.acceptOffer(
        offerId: params.offerId,
        expectedAmount: params.expectedAmount,
      );
}
