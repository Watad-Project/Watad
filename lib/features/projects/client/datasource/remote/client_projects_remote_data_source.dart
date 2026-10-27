import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_task_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_saved_address_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_task_update_model.dart';
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

  /// The client's projects (`v_my_projects`, `my_role = 'owner'`), newest
  /// first.
  Future<List<ClientProjectModel>> getMyProjects();

  Future<ClientProjectModel> getProject(String projectId);

  /// The offers on a project (`v_project_offers`), cheapest first.
  Future<List<ClientProjectOfferModel>> getOffers(String projectId);

  Future<void> acceptOffer(String offerId, Money expectedAmount);

  /// Uploads [filePath] to `project-deeds` and points the project at it; the
  /// deed goes back to review (trigger on `deed_storage_path`).
  Future<void> replaceDeed(String projectId, String filePath);

  /// The tasks of a project (`v_project_tasks`, `my_role = 'owner'`), by
  /// start date (tasks without one last), then by when they were added.
  Future<List<ClientProjectTaskModel>> getProjectTasks(String projectId);

  /// One task (`v_project_tasks`, `my_role = 'owner'`).
  Future<ClientProjectTaskModel> getProjectTask(String taskId);

  /// `set_task_status`: the client's answer to a proposed task.
  Future<void> setTaskStatus(String taskId, TaskStatus status);

  /// One update (`v_project_task_updates`, `my_role = 'owner'`), with the
  /// project's status and contractor (`v_my_projects`) and signed links to
  /// its evidence photos (`task-evidence`).
  Future<ClientTaskUpdateModel> getTaskUpdate(String updateId);

  /// `decide_task_update`: accepts or rejects a pending update.
  Future<void> decideTaskUpdate(
    String updateId,
    TaskUpdateDecision decision, {
    String? rejectionReason,
    String? rejectionDetails,
  });
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
      final file = File(photoPath);
      if (!file.existsSync()) {
        throw FileSystemException(
          'Project photo not found on device',
          photoPath,
        );
      }
      final remotePath = await uploadProjectPhoto(filePath: photoPath);
      photoPaths.add(remotePath);
    }

    String? deedPath;
    if (project.deedFilePath != null && project.deedFilePath!.isNotEmpty) {
      final file = File(project.deedFilePath!);
      if (!file.existsSync()) {
        throw FileSystemException(
          'Project ownership deed file not found on device',
          project.deedFilePath!,
        );
      }
      deedPath = await uploadDeedDocument(filePath: project.deedFilePath!);
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
    final storagePath = '$userId/$fileName';
    await _client.storage
        .from('project-deeds')
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

  static const String _projectColumns =
      'id, title, status, city, district, budget, pending_offer_count, '
      'created_at, deed_status, deed_rejection_reason, photo_paths, '
      'taker_id, taker_company_name, agreed_amount';

  @override
  Future<List<ClientProjectModel>> getMyProjects() async {
    final rows = await _client
        .from('v_my_projects')
        .select(_projectColumns)
        .eq('my_role', 'owner')
        .order('created_at', ascending: false);
    return _withPhotosAndTasks(rows);
  }

  @override
  Future<ClientProjectModel> getProject(String projectId) async {
    final row = await _client
        .from('v_my_projects')
        .select(_projectColumns)
        .eq('my_role', 'owner')
        .eq('id', projectId)
        .single();
    return (await _withPhotosAndTasks([row])).single;
  }

  /// [rows] with their first photo's public URL (`images` is a public
  /// bucket) and their tasks counted, in one `v_project_tasks` read.
  Future<List<ClientProjectModel>> _withPhotosAndTasks(
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = [for (final row in rows) row['id'] as String];
    final tasks = ids.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from('v_project_tasks')
              .select('project_id, status')
              .inFilter('project_id', ids);
    final counted = <String, int>{};
    final approved = <String, int>{};
    for (final task in tasks) {
      final status = task['status'] as String?;
      // A rejected task isn't part of the work.
      if (status == 'rejected') continue;
      final projectId = task['project_id'] as String;
      counted.update(projectId, (n) => n + 1, ifAbsent: () => 1);
      if (status == 'approved') {
        approved.update(projectId, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final images = _client.storage.from('images');
    return [
      for (final row in rows)
        ClientProjectModel.fromJson({
          ...row,
          'photo_url': switch (row['photo_paths']) {
            [final String first, ...] when first.isNotEmpty =>
              images.getPublicUrl(first),
            _ => null,
          },
          'task_count': counted[row['id']] ?? 0,
          'approved_task_count': approved[row['id']] ?? 0,
        }),
    ];
  }

  @override
  Future<List<ClientProjectOfferModel>> getOffers(String projectId) async {
    final rows = await _client
        .from('v_project_offers')
        .select(
          'id, project_id, provider_id, amount, status, message, created_at, '
          'provider_company_name, provider_is_verified, provider_rating_avg, '
          'provider_rating_count',
        )
        .eq('project_id', projectId)
        // Cheapest first, as in the design.
        .order('amount', ascending: true);
    return rows.map(ClientProjectOfferModel.fromJson).toList();
  }

  @override
  Future<void> acceptOffer(String offerId, Money expectedAmount) async {
    await _client.rpc<void>(
      'accept_offer',
      params: {
        'p_offer_id': offerId,
        'p_expected_amount': expectedAmount.toJson(),
      },
    );
  }

  @override
  Future<void> replaceDeed(String projectId, String filePath) async {
    final path = await uploadDeedDocument(filePath: filePath);
    // Only the UPDATE column allowed on `projects` (ARCHITECTURE.md §3a).
    await _client
        .from('projects')
        .update({'deed_storage_path': path})
        .eq('id', projectId);
  }

  static const String _taskColumns =
      'id, title, description, amount, status, payment_status, start_date, '
      'finish_date, last_update_id';

  @override
  Future<List<ClientProjectTaskModel>> getProjectTasks(String projectId) async {
    final rows = await _client
        .from('v_project_tasks')
        .select(_taskColumns)
        .eq('project_id', projectId)
        .eq('my_role', 'owner')
        // Postgrest sorts descending unless asked; empty start dates last.
        .order('start_date', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(ClientProjectTaskModel.fromJson).toList();
  }

  @override
  Future<ClientProjectTaskModel> getProjectTask(String taskId) async {
    final row = await _client
        .from('v_project_tasks')
        .select(_taskColumns)
        .eq('id', taskId)
        .eq('my_role', 'owner')
        .single();
    return ClientProjectTaskModel.fromJson(row);
  }

  @override
  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    await _client.rpc<void>(
      'set_task_status',
      params: {'p_task_id': taskId, 'p_status': status.toJson()},
    );
  }

  static const String _updateColumns =
      'id, project_id, task_title, task_amount, proposed_state, note, '
      'photo_paths, decision, rejection_reason, rejection_details, created_at';

  /// How long a link to an evidence photo works.
  static const int _signedUrlSeconds = 10 * 60;

  @override
  Future<ClientTaskUpdateModel> getTaskUpdate(String updateId) async {
    final row = await _client
        .from('v_project_task_updates')
        .select(_updateColumns)
        .eq('id', updateId)
        .eq('my_role', 'owner')
        .single();
    final project = await _client
        .from('v_my_projects')
        .select('status, taker_company_name, taker_avatar_path')
        .eq('id', row['project_id'] as String)
        .eq('my_role', 'owner')
        .single();
    final evidence = _client.storage.from('task-evidence');
    final paths = [
      for (final path in row['photo_paths'] as List<dynamic>? ?? const [])
        path as String,
    ];
    final links = await Future.wait(
      paths.map((path) => _signedUrl(evidence, path)),
    );
    final avatar = project['taker_avatar_path'] as String?;
    return ClientTaskUpdateModel.fromJson({
      ...row,
      'photo_urls': [for (final link in links) ?link],
      'project_status': project['status'],
      'contractor_name': project['taker_company_name'],
      // Photos of people are in the public `avatars` bucket.
      'contractor_avatar_url': avatar == null || avatar.isEmpty
          ? null
          : _client.storage.from('avatars').getPublicUrl(avatar),
    });
  }

  /// A short-lived link to [path] in a private bucket, or null when the
  /// file isn't there (never uploaded, or removed): the rest still shows.
  Future<String?> _signedUrl(StorageFileApi bucket, String path) async =>
      await bucket.exists(path)
      ? await bucket.createSignedUrl(path, _signedUrlSeconds)
      : null;

  @override
  Future<void> decideTaskUpdate(
    String updateId,
    TaskUpdateDecision decision, {
    String? rejectionReason,
    String? rejectionDetails,
  }) async {
    await _client.rpc<void>(
      'decide_task_update',
      params: {
        'p_update_id': updateId,
        'p_decision': decision.toJson(),
        'p_rejection_reason': rejectionReason,
        'p_rejection_details': rejectionDetails,
      },
    );
  }
}
