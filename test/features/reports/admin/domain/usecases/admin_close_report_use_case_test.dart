import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_close_report_use_case.dart';

import '../../../../../helpers/fake_admin_reports_repository.dart';

void main() {
  late FakeAdminReportsRepository repository;

  setUp(() => repository = FakeAdminReportsRepository());

  Matcher isValidationFailure(String key) => isA<Failed<void>>().having(
    (f) => f.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'messageKey', key),
  );

  group('closing a report', () {
    test('resolves or dismisses it', () async {
      final close = AdminCloseReportUseCase(repository);

      await close(
        const AdminReportClosure(
          reportId: 'r-1',
          status: ReportStatus.resolved,
        ),
      );
      await close(
        const AdminReportClosure(
          reportId: 'r-2',
          status: ReportStatus.dismissed,
        ),
      );

      expect(repository.calls, [
        'close r-1 resolved: null',
        'close r-2 dismissed: null',
      ]);
    });

    test('refuses any other status', () async {
      final result = await AdminCloseReportUseCase(repository)(
        const AdminReportClosure(
          reportId: 'r-1',
          status: ReportStatus.inReview,
        ),
      );

      expect(result, isValidationFailure('validation.invalid'));
      expect(repository.calls, isEmpty);
    });
  });
}
