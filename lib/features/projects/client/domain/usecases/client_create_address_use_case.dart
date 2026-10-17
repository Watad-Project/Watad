import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientCreateAddressParams {
  const ClientCreateAddressParams({
    required this.name,
    required this.city,
    required this.district,
    required this.street,
    required this.buildingNumber,
    required this.postalCode,
  });

  final String name;
  final String city;
  final String district;
  final String street;
  final String buildingNumber;
  final String postalCode;
}

class ClientCreateAddressUseCase
    implements UseCase<ClientSavedAddress, ClientCreateAddressParams> {
  const ClientCreateAddressUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<ClientSavedAddress>> call(ClientCreateAddressParams params) =>
      _repository.createAddress(
        name: params.name,
        city: params.city,
        district: params.district,
        street: params.street,
        buildingNumber: params.buildingNumber,
        postalCode: params.postalCode,
      );
}
