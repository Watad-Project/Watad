import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

/// «مقاولون مقترحون»: the five best rated verified contractors.
class ClientGetSuggestedContractorsUseCase
    implements UseCase<List<ClientContractor>, NoParams> {
  const ClientGetSuggestedContractorsUseCase(this._repository);

  final ClientHomeRepository _repository;

  @override
  Future<Result<List<ClientContractor>>> call(NoParams params) =>
      _repository.getSuggestedContractors();
}
