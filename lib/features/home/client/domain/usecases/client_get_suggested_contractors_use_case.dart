import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

final class ClientGetSuggestedContractorsUseCase
    implements UseCase<List<ClientSuggestedContractor>, NoParams> {
  const ClientGetSuggestedContractorsUseCase(this._repository);

  final ClientHomeRepository _repository;

  @override
  Future<Result<List<ClientSuggestedContractor>>> call(NoParams params) {
    return _repository.getSuggestedContractors();
  }
}
