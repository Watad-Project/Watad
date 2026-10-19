import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

/// The cities of the city filter: where verified contractors work.
class ClientGetContractorCitiesUseCase
    implements UseCase<List<String>, NoParams> {
  const ClientGetContractorCitiesUseCase(this._repository);

  final ClientHomeRepository _repository;

  @override
  Future<Result<List<String>>> call(NoParams params) =>
      _repository.getContractorCities();
}
