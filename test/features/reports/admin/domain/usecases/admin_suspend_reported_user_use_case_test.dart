import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_suspend_reported_user_use_case.dart';

import '../../../../../helpers/fake_admin_reports_repository.dart';

void main() {
  late FakeAdminReportsRepository repository;

  setUp(() => repository = FakeAdminReportsRepository());

  Matcher isValidationFailure(String key) => isA<Failed<void>>().having(
    (f) => f.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'messageKey', key),
  );

  group('suspending a reported user', () {
    test('suspends them, then resolves the report with the reason', () async {
      final result = await AdminSuspendReportedUserUseCase(repository)(
        const AdminReportDecision(
          reportId: 'r-2',
          subjectId: 'u-9',
          reason: 'رسائل مسيئة',
        ),
      );

      expect(result, isA<Success<void>>());
      expect(repository.calls, [
        'suspend u-9: رسائل مسيئة',
        'close r-2 resolved: رسائل مسيئة',
      ]);
    });

    test('needs a reason', () async {
      final result = await AdminSuspendReportedUserUseCase(repository)(
        const AdminReportDecision(
          reportId: 'r-2',
          subjectId: 'u-9',
          reason: '',
        ),
      );

      expect(result, isValidationFailure('common.reason_required'));
      expect(repository.calls, isEmpty);
    });
  });
}
