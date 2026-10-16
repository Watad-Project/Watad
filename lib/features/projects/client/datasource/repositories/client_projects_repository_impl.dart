import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientProjectsRepositoryImpl implements ClientProjectsRepository {
  const ClientProjectsRepositoryImpl(this._remote);

  final ClientProjectsRemoteDataSource _remote;

  @override
  Future<Result<void>> createProject(ClientNewProject project) =>
      guardSupabaseCall(() => _remote.createProject(project));

  @override
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses() =>
      guardSupabaseCall(_remote.getSavedAddresses);

  @override
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) => guardSupabaseCall(
    () => _remote.createAddress(
      name: name,
      city: city,
      district: district,
      street: street,
      buildingNumber: buildingNumber,
      postalCode: postalCode,
    ),
  );
}
