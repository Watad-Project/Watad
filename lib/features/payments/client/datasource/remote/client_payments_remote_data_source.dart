import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/payments/client/datasource/models/client_payment_task_model.dart';

abstract interface class ClientPaymentsRemoteDataSource {
  /// The tasks of a project with their payment stages (`v_project_tasks`,
  /// `my_role = 'owner'`), by start date (tasks without one last), then by
  /// when they were added.
  Future<List<ClientPaymentTaskModel>> getTasks(String projectId);
}

class ClientPaymentsRemoteDataSourceImpl
    implements ClientPaymentsRemoteDataSource {
  const ClientPaymentsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _taskColumns =
      'id, title, amount, status, payment_id, payment_status';

  @override
  Future<List<ClientPaymentTaskModel>> getTasks(String projectId) async {
    final rows = await _client
        .from('v_project_tasks')
        .select(_taskColumns)
        .eq('project_id', projectId)
        .eq('my_role', 'owner')
        // Postgrest sorts descending unless asked; empty start dates last.
        .order('start_date', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(ClientPaymentTaskModel.fromJson).toList();
  }
}
