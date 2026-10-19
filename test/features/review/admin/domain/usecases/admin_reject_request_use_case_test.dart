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

  test('with «أخرى» (no reason) the details are the whole note', () async {
    final result = await useCase(
      const AdminReviewRejection(
        businessId: 'b-1',
        details: ' الختم غير ظاهر ',
      ),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [('b-1', 'الختم غير ظاهر')]);
  });

  test('a listed reason needs no details', () async {
    final result = await useCase(
      const AdminReviewRejection(
        businessId: 'b-1',
        reason: 'المستند منتهي الصلاحية',
        details: '',
      ),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [('b-1', 'المستند منتهي الصلاحية')]);
  });

  test('«أخرى» without details is refused', () async {
    final result = await useCase(
      const AdminReviewRejection(businessId: 'b-1', details: '  '),
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
  });
}
