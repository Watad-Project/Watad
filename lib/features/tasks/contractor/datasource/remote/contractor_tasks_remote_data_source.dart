import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_project_task_model.dart';
import 'package:watad/features/tasks/contractor/datasource/models/contractor_task_project_model.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_new_task.dart';

abstract interface class ContractorTasksRemoteDataSource {
  Future<ContractorTaskProjectModel> getProject(String projectId);

  Future<List<ContractorProjectTaskModel>> getProjectTasks(String projectId);

  Future<void> createTask(ContractorNewTask task);
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
  Future<void> createTask(ContractorNewTask task) async {
    await _client.from('project_tasks').insert({
      'project_id': task.projectId,
      'title': task.title,
      'description': task.description,
      'amount': task.amount?.toJson(),
      'start_date': _formatCalendarDay(task.startDate),
    });
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

  static String? _formatCalendarDay(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
