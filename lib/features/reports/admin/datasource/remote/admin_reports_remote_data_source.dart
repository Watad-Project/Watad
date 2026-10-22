import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/features/reports/admin/datasource/models/admin_report_model.dart';

abstract interface class AdminReportsRemoteDataSource {
  Future<List<AdminReportModel>> getOpenReports();

  Future<void> assignToMe(String reportId);

  Future<void> removeListing(String itemId, String reason);

  Future<void> suspendUser(String userId, String reason);

  Future<void> close(String reportId, ReportStatus status, {String? note});
}

class AdminReportsRemoteDataSourceImpl implements AdminReportsRemoteDataSource {
  const AdminReportsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminReportModel>> getOpenReports() async {
    final rows = await _client
        .from('v_admin_help_reports')
        .select(
          'id, report_type, status, target_type, target_id, reporter_name, '
          'target_user_id, target_user_name, created_at',
        )
        .inFilter('status', [
          ReportStatus.open.toJson(),
          ReportStatus.inReview.toJson(),
        ])
        .order('created_at', ascending: false);
    return rows.map(AdminReportModel.fromJson).toList();
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
    String? note,
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
