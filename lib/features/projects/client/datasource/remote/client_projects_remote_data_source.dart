import 'dart:io';

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
  Future<String> uploadProjectPhoto({required String filePath});
  Future<String> uploadDeedDocument({required String filePath});
}

class ClientProjectsRemoteDataSourceImpl
    implements ClientProjectsRemoteDataSource {
  const ClientProjectsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static String _resolveImageContentType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String _resolveDeedContentType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/pdf';
    }
  }

  @override
  Future<void> createProject(ClientNewProject project) async {
    final photoPaths = <String>[];
    for (final photoPath in project.photos) {
      if (File(photoPath).existsSync()) {
        final remotePath = await uploadProjectPhoto(filePath: photoPath);
        photoPaths.add(remotePath);
      } else {
        photoPaths.add(photoPath);
      }
    }

    String? deedPath;
    if (project.deedFilePath != null && project.deedFilePath!.isNotEmpty) {
      if (File(project.deedFilePath!).existsSync()) {
        deedPath = await uploadDeedDocument(filePath: project.deedFilePath!);
      } else {
        deedPath = project.deedFilePath;
      }
    }

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
      'photo_paths': photoPaths,
      'deed_storage_path': ?deedPath,
    });
  }

  @override
  Future<String> uploadProjectPhoto({required String filePath}) async {
    final userId = _client.auth.currentUser?.id;
    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'photo.$ext'}';
    final storagePath = '$userId/projects/$fileName';
    await _client.storage
        .from('images')
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: _resolveImageContentType(filePath),
          ),
        );
    return storagePath;
  }

  @override
  Future<String> uploadDeedDocument({required String filePath}) async {
    final userId = _client.auth.currentUser?.id;
    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'deed.$ext'}';
    final storagePath = '$userId/projects/$fileName';
    await _client.storage
        .from('images')
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: _resolveDeedContentType(filePath),
          ),
        );
    return storagePath;
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
