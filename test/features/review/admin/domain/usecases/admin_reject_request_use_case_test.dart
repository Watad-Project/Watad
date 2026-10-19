import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';

void main() {
  late FakeAdminReviewRepository repository;
  late AdminRejectRequestUseCase useCase;

  setUp(() {
    repository = FakeAdminReviewRepository();
    useCase = AdminRejectRequestUseCase(repository);
  });

  test('sends the reason and the details as one note', () async {
    final result = await useCase(
      const AdminReviewRejection(
        businessId: 'b-1',
        reason: ' الصورة غير واضحة ',
        details: ' أعد التصوير بإضاءة أفضل ',
      ),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [
      ('b-1', 'الصورة غير واضحة: أعد التصوير بإضاءة أفضل'),
    ]);
  });

  for (final (reason, details) in [('', 'details'), ('reason', '  ')]) {
    test(
      'refuses an empty reason or details ("$reason", "$details")',
      () async {
        final result = await useCase(
          AdminReviewRejection(
            businessId: 'b-1',
            reason: reason,
            details: details,
          ),
        );

        expect(
          result,
          isA<Failed<void>>().having(
            (f) => f.failure,
            'failure',
            isA<ValidationFailure>().having(
              (f) => f.messageKey,
              'messageKey',
              'common.reason_required',
            ),
          ),
        );
        expect(repository.rejected, isEmpty);
      },
    );
  }
}
