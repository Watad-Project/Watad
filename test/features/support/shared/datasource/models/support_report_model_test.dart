import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/support/shared/datasource/models/support_report_model.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';

void main() {
  test('fromJson maps a resolved v_my_help_reports row about an order', () {
    final report = SupportReportModel.fromJson(const {
      'id': '5c1d2e3f-0000-4000-8000-000000000001',
      'report_type': 'payment_issue',
      'description': 'دفعت للطلب ولم تتغير حالته',
      'status': 'resolved',
      'resolution_note': ' تم تحديث حالة الطلب ',
      'target_type': 'order',
      'created_at': '2026-11-02T10:00:00+00:00',
      'resolved_at': '2026-11-03T09:00:00+00:00',
    });

    expect(report.type, ReportType.paymentIssue);
    expect(report.status, ReportStatus.resolved);
    expect(report.resolutionNote, 'تم تحديث حالة الطلب');
    expect(report.targetKind, SupportTargetKind.order);
    expect(report.createdAt, DateTime.utc(2026, 11, 2, 10));
    expect(report.resolvedAt, DateTime.utc(2026, 11, 3, 9));
  });

  test('an open report about nothing', () {
    final report = SupportReportModel.fromJson(const {
      'id': 'r-1',
      'report_type': 'technical_issue',
      'description': 'التطبيق يغلق',
      'status': 'in_review',
      'resolution_note': null,
      'target_type': null,
      'created_at': '2026-10-30T08:00:00+00:00',
      'resolved_at': null,
    });

    expect(report.status, ReportStatus.inReview);
    expect(report.resolutionNote, isNull);
    expect(report.targetKind, isNull);
    expect(report.resolvedAt, isNull);
  });
}
