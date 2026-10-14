import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';

abstract interface class ClientProjectsRemoteDataSource {
  Future<void> createProject(ClientNewProject project);
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
}
