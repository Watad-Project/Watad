import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_saved_address_model.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';

abstract interface class ClientProjectsRemoteDataSource {
  Future<void> createProject(ClientNewProject project);
  Future<List<ClientSavedAddressModel>> getSavedAddresses();
  Future<ClientSavedAddressModel> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  });
}

class ClientProjectsRemoteDataSourceImpl
    implements ClientProjectsRemoteDataSource {
  const ClientProjectsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> createProject(ClientNewProject project) async {
    // Only the INSERT columns allowed on `projects` (ARCHITECTURE.md §3a).
    await _client.from('projects').insert({
      'title': project.title,
      'description': project.description,
      'budget': project.budget?.toJson(),
      'city': project.city,
      'district': project.district,
      'address_id': project.addressId,
      'status': (project.publish ? ProjectStatus.open : ProjectStatus.draft)
          .toJson(),
    });
  }

  @override
  Future<List<ClientSavedAddressModel>> getSavedAddresses() async {
    final response = await _client
        .from('v_my_addresses')
        .select()
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map(
          (json) =>
              ClientSavedAddressModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<ClientSavedAddressModel> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) async {
    // Only the 6 allowed INSERT columns for `addresses` (ARCHITECTURE.md §3a).
    final response = await _client
        .from('addresses')
        .insert({
          'name': name.trim(),
          'city': city.trim(),
          'district': district.trim(),
          'street': street.trim(),
          'building_number': buildingNumber.trim(),
          'postal_code': postalCode.trim(),
        })
        .select()
        .single();
    return ClientSavedAddressModel.fromJson(response);
  }
}
