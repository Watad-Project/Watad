import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_type_filter.dart';

void main() {
  AdminReport report(ReportType type) => AdminReport(
    id: 'r-1',
    type: type,
    status: ReportStatus.open,
    createdAt: DateTime.utc(2026, 10, 18),
  );

  test('support has the technical, payment and other tickets', () {
    final support = [
      for (final type in ReportType.values)
        if (AdminReportsTypeFilter.support.matches(report(type))) type,
    ];
    expect(support, [
      ReportType.paymentIssue,
      ReportType.technicalIssue,
      ReportType.other,
    ]);
  });

  test('moderation has the rest, and all has every type', () {
    for (final type in ReportType.values) {
      expect(
        AdminReportsTypeFilter.moderation.matches(report(type)),
        !AdminReportsTypeFilter.support.matches(report(type)),
      );
      expect(AdminReportsTypeFilter.all.matches(report(type)), isTrue);
    }
  });
}
