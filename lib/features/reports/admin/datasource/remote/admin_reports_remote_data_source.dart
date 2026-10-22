import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/features/reports/admin/datasource/models/admin_report_model.dart';

abstract interface class AdminReportsRemoteDataSource {
  Future<List<AdminReportModel>> getReports();

  /// Throws PGRST116 (not found) when no ticket has [reportId].
  Future<AdminReportModel> getReport(String reportId);

  Future<void> assignToMe(String reportId);

  Future<void> removeListing(String itemId, String reason);

  Future<void> suspendUser(String userId, String reason);

  Future<void> close(
    String reportId,
    ReportStatus status, {
    required String note,
  });
}

class AdminReportsRemoteDataSourceImpl implements AdminReportsRemoteDataSource {
  const AdminReportsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, report_type, description, status, target_type, target_id, '
      'evidence_snapshot, reporter_name, target_user_id, target_user_name, '
      'assigned_admin_id, assigned_admin_name, resolution_note, created_at, '
      'resolved_at';

  /// [row] with `assigned_to_me`, for «مسندة لي»: whether it is assigned
  /// to the signed-in admin.
  Map<String, dynamic> _withMine(Map<String, dynamic> row) {
    final myId = _client.auth.currentUser?.id;
    return {
      ...row,
      'assigned_to_me': myId != null && row['assigned_admin_id'] == myId,
    };
  }

  @override
  Future<List<AdminReportModel>> getReports() async {
    final rows = await _client
        .from('v_admin_help_reports')
        .select(_columns)
        .order('created_at', ascending: false);
    return rows
        .map((row) => AdminReportModel.fromJson(_withMine(row)))
        .toList();
  }

  @override
  Future<AdminReportModel> getReport(String reportId) async {
    final row = await _client
        .from('v_admin_help_reports')
        .select(_columns)
        .eq('id', reportId)
        .single();
    return AdminReportModel.fromJson(_withMine(row));
  }

  @override
  Future<void> assignToMe(String reportId) async {
    // Without p_admin_id the server assigns the caller.
    await _client.rpc<void>(
      'admin_assign_help_report',
      params: {'p_report_id': reportId},
    );
  }

  @override
  Future<void> removeListing(String itemId, String reason) async {
    await _client.rpc<void>(
      'admin_remove_listing',
      params: {'p_item_id': itemId, 'p_reason': reason},
    );
  }

  @override
  Future<void> suspendUser(String userId, String reason) async {
    await _client.rpc<void>(
      'admin_set_user_suspension',
      params: {'p_user_id': userId, 'p_suspended': true, 'p_reason': reason},
    );
  }

  @override
  Future<void> close(
    String reportId,
    ReportStatus status, {
    required String note,
  }) async {
    await _client.rpc<void>(
      'admin_resolve_help_report',
      params: {
        'p_report_id': reportId,
        'p_status': status.toJson(),
        'p_note': note,
      },
    );
  }
}
