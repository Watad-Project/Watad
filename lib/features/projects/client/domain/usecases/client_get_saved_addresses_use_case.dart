import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientGetSavedAddressesUseCase
    implements UseCase<List<ClientSavedAddress>, NoParams> {
  const ClientGetSavedAddressesUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<List<ClientSavedAddress>>> call([
    NoParams params = const NoParams(),
  ]) => _repository.getSavedAddresses();
}
