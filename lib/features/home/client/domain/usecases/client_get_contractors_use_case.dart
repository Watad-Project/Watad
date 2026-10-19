import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_contractors_query.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

/// One page of the «الكل» contractors list.
class ClientGetContractorsUseCase
    implements UseCase<List<ClientContractor>, ClientContractorsQuery> {
  const ClientGetContractorsUseCase(this._repository);

  final ClientHomeRepository _repository;

  @override
  Future<Result<List<ClientContractor>>> call(ClientContractorsQuery params) =>
      _repository.getContractors(params);
}
