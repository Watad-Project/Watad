import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';

abstract interface class ClientProjectsRepository {
  Future<Result<void>> createProject(ClientNewProject project);
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses();
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  });
}
