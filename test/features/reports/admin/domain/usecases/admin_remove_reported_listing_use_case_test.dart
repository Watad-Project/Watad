import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_remove_reported_listing_use_case.dart';

import '../../../../../helpers/fake_admin_reports_repository.dart';

void main() {
  late FakeAdminReportsRepository repository;

  setUp(() => repository = FakeAdminReportsRepository());

  Matcher isValidationFailure(String key) => isA<Failed<void>>().having(
    (f) => f.failure,
    'failure',
    isA<ValidationFailure>().having((f) => f.messageKey, 'messageKey', key),
  );

  group('removing a reported listing', () {
    test('removes it, then resolves the report with the reason', () async {
      final result = await AdminRemoveReportedListingUseCase(repository)(
        const AdminReportDecision(
          reportId: 'r-1',
          subjectId: 'i-1',
          reason: ' إعلان مضلل ',
        ),
      );

      expect(result, isA<Success<void>>());
      expect(repository.calls, [
        'remove i-1: إعلان مضلل',
        'close r-1 resolved: إعلان مضلل',
      ]);
    });

    test('needs a reason', () async {
      final result = await AdminRemoveReportedListingUseCase(repository)(
        const AdminReportDecision(
          reportId: 'r-1',
          subjectId: 'i-1',
          reason: ' ',
        ),
      );

      expect(result, isValidationFailure('common.reason_required'));
      expect(repository.calls, isEmpty);
    });

    test(
      'keeps the report open when the listing could not be removed',
      () async {
        repository.actionResult = const Failed(ConflictFailure());

        final result = await AdminRemoveReportedListingUseCase(repository)(
          const AdminReportDecision(
            reportId: 'r-1',
            subjectId: 'i-1',
            reason: 'x',
          ),
        );

        expect(result, isA<Failed<void>>());
        expect(repository.calls, ['remove i-1: x']);
      },
    );
  });
}
