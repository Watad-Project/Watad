import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_status_filter.dart';

void main() {
  AdminReport report(ReportStatus status, {bool mine = false}) => AdminReport(
    id: 'r-1',
    type: ReportType.other,
    status: status,
    isAssignedToMe: mine,
    createdAt: DateTime.utc(2026, 10, 18),
  );

  test('each chip takes its statuses', () {
    expect(
      AdminReportsStatusFilter.open.matches(report(ReportStatus.open)),
      isTrue,
    );
    expect(
      AdminReportsStatusFilter.inReview.matches(report(ReportStatus.inReview)),
      isTrue,
    );
    expect(
      AdminReportsStatusFilter.closed.matches(report(ReportStatus.resolved)),
      isTrue,
    );
    expect(
      AdminReportsStatusFilter.closed.matches(report(ReportStatus.dismissed)),
      isTrue,
    );
    expect(
      AdminReportsStatusFilter.open.matches(report(ReportStatus.inReview)),
      isFalse,
    );
  });

  test('«مسندة لي» has my tickets still to handle', () {
    const mine = AdminReportsStatusFilter.assignedToMe;
    expect(mine.matches(report(ReportStatus.inReview, mine: true)), isTrue);
    expect(mine.matches(report(ReportStatus.inReview)), isFalse);
    // Once closed, it is under «مغلقة» only.
    expect(mine.matches(report(ReportStatus.resolved, mine: true)), isFalse);
  });
}
