import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/datasource/models/admin_report_model.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';

void main() {
  test('fromJson maps a v_admin_help_reports row about a listing', () {
    final row = {
      'id': '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69',
      'report_type': 'fraud',
      'status': 'in_review',
      'target_type': 'marketplace_item',
      'target_id': 'a1b2c3d4-0000-4000-8000-000000000001',
      'reporter_name': 'عبدالله الحربي',
      'target_user_id': null,
      'target_user_name': null,
      'created_at': '2026-10-18T21:05:00+00:00',
    };

    final model = AdminReportModel.fromJson(row);

    expect(model.id, '5f0c7a52-3d1e-4c8b-9b7a-1e2d3c4b5a69');
    expect(model.type, ReportType.fraud);
    expect(model.status, ReportStatus.inReview);
    expect(model.target, AdminReportTarget.marketplaceItem);
    expect(model.listingId, 'a1b2c3d4-0000-4000-8000-000000000001');
    expect(model.reporterName, 'عبدالله الحربي');
    expect(model.targetUserId, isNull);
    expect(model.createdAt, DateTime.utc(2026, 10, 18, 21, 5));
  });

  test('fromJson maps a report about a user', () {
    final model = AdminReportModel.fromJson({
      'id': 'r-2',
      'report_type': 'payment_issue',
      'status': 'open',
      'target_type': 'user',
      'target_id': 'u-9',
      'reporter_name': 'Sara',
      'target_user_id': 'u-9',
      'target_user_name': 'Khalid',
      'created_at': '2026-10-18T21:05:00+00:00',
    });

    expect(model.type, ReportType.paymentIssue);
    expect(model.status, ReportStatus.open);
    expect(model.target, AdminReportTarget.user);
    expect(model.listingId, isNull);
    expect(model.targetUserId, 'u-9');
    expect(model.targetUserName, 'Khalid');
  });

  test('a report without a target has none', () {
    final model = AdminReportModel.fromJson({
      'id': 'r-3',
      'report_type': 'technical_issue',
      'status': 'open',
      'target_type': null,
      'target_id': null,
      'reporter_name': null,
      'target_user_id': null,
      'target_user_name': null,
      'created_at': '2026-10-18T21:05:00+00:00',
    });

    expect(model.target, isNull);
    expect(model.reporterName, isNull);
  });
}
