import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_project_task_model.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_task_project_model.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_submit_task_update_params.dart';

abstract interface class ContractorTasksRemoteDataSource {
  Future<ContractorTaskProjectModel> getProject(String projectId);

  Future<List<ContractorProjectTaskModel>> getProjectTasks(String projectId);

  Future<String> submitTaskUpdate(ContractorSubmitTaskUpdateParams params);
}

class ContractorTasksRemoteDataSourceImpl
    implements ContractorTasksRemoteDataSource {
  const ContractorTasksRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _contractorRole = 'taker';

  static const String _projectColumns =
      'id, title, status, owner_id, owner_name, city, district, '
      'agreed_amount, budget, total_paid, total_scheduled, '
      'photo_paths, created_at, completed_at';

  static const String _taskColumns =
      'id, project_id, title, description, amount, status, '
      'payment_id, payment_status, start_date, finish_date, decided_at, '
      'created_at, last_update_id, last_update_proposed_state, '
      'last_update_decision, last_update_at, has_pending_update';

  @override
  Future<ContractorTaskProjectModel> getProject(String projectId) async {
    final row = await _client
        .from('v_my_projects')
        .select(_projectColumns)
        .eq('my_role', _contractorRole)
        .eq('id', projectId)
        .single();
    return ContractorTaskProjectModel.fromJson(_withPhotoUrl(row));
  }

  @override
  Future<List<ContractorProjectTaskModel>> getProjectTasks(
    String projectId,
  ) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('v_project_tasks')
        .select(_taskColumns)
        .eq('my_role', _contractorRole)
        .eq('project_id', projectId)
        .order('start_date', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(ContractorProjectTaskModel.fromJson).toList();
  }

  @override
  Future<String> submitTaskUpdate(
    ContractorSubmitTaskUpdateParams params,
  ) async {
    final userId = _client.auth.currentUser?.id;
    final photoPaths = <String>[];

    if (params.photos.isNotEmpty) {
      if (userId == null || userId.isEmpty) {
        throw const AuthException('Not authenticated');
      }
      final bucket = _client.storage.from('task-evidence');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < params.photos.length; i++) {
        final photo = params.photos[i];
        final cleanName = _sanitizeFileName(photo.fileName, fallbackIndex: i);
        final path = '$userId/${timestamp}_${i}_$cleanName';
        await bucket.uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(contentType: _contentType(cleanName)),
        );
        photoPaths.add(path);
      }
    }

    return _client.rpc<String>(
      'submit_task_update',
      params: {
        'p_task_id': params.taskId,
        'p_proposed_state': params.proposedState.toJson(),
        'p_note': params.note,
        'p_photo_paths': photoPaths,
      },
    );
  }

  Map<String, dynamic> _withPhotoUrl(Map<String, dynamic> row) {
    final paths = row['photo_paths'] as List<dynamic>?;
    final first = paths == null || paths.isEmpty
        ? null
        : paths.first as String?;
    if (first == null || first.isEmpty) return row;
    return {
      ...row,
      'photo_url': _client.storage.from('images').getPublicUrl(first),
    };
  }

  static String _sanitizeFileName(String name, {required int fallbackIndex}) {
    final sanitized = name.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');
    return sanitized.isEmpty ? 'evidence_$fallbackIndex.jpg' : sanitized;
  }

  static String _contentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
