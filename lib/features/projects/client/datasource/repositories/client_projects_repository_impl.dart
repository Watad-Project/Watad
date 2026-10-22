import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
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

  @override
  Future<Result<List<ClientProject>>> getMyProjects() =>
      guardSupabaseCall(_remote.getMyProjects);

  @override
  Future<Result<ClientProject>> getProject(String projectId) =>
      guardSupabaseCall(() => _remote.getProject(projectId));

  @override
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId) =>
      guardSupabaseCall(() => _remote.getOffers(projectId));

  @override
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params) =>
      guardSupabaseCall(
        () => _remote.acceptOffer(params.offerId, params.expectedAmount),
      );

  @override
  Future<Result<void>> replaceDeed(ClientReplaceDeedParams params) =>
      guardSupabaseCall(
        () => _remote.replaceDeed(params.projectId, params.filePath),
      );
}
