import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/support/shared/datasource/models/support_report_model.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';

abstract interface class SupportRemoteDataSource {
  /// My `v_my_help_reports` rows, newest first.
  Future<List<SupportReportModel>> getMyReports();

  /// Inserts [report] into `help_reports` (ARCHITECTURE.md §3a): its type,
  /// description and at most one `target_*` column. `reporter_id` and the
  /// status come from the database.
  Future<void> sendReport(SupportNewReport report);
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  const SupportRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SupportReportModel>> getMyReports() async {
    final rows = await _client
        .from('v_my_help_reports')
        .select(
          'id, report_type, description, status, resolution_note, '
          'target_type, created_at, resolved_at',
        )
        .order('created_at', ascending: false);
    return rows.map(SupportReportModel.fromJson).toList();
  }

  @override
  Future<void> sendReport(SupportNewReport report) async {
    final target = report.target;
    await _client.from('help_reports').insert({
      'report_type': report.type.toJson(),
      'description': report.description,
      if (target != null) _targetColumn(target.kind): target.id,
    });
  }

  static String _targetColumn(SupportTargetKind kind) => switch (kind) {
    SupportTargetKind.user => 'target_user_id',
    SupportTargetKind.project => 'target_project_id',
    SupportTargetKind.item => 'target_item_id',
    SupportTargetKind.order => 'target_order_id',
    SupportTargetKind.review => 'target_review_id',
    SupportTargetKind.message => 'target_message_id',
  };
}
