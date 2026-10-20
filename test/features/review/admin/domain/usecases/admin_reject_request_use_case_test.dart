import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';

void main() {
  const license = AdminReviewTarget(kind: AdminReviewKind.license, id: 'b-1');
  const deed = AdminReviewTarget(kind: AdminReviewKind.deed, id: 'p-1');

  late FakeAdminReviewRepository repository;
  late AdminRejectRequestUseCase useCase;

  setUp(() {
    repository = FakeAdminReviewRepository();
    useCase = AdminRejectRequestUseCase(repository);
  });

  test('sends the reason and the details as one note', () async {
    final result = await useCase(
      const AdminReviewRejection(
        target: license,
        reason: ' الصورة غير واضحة ',
        details: ' أعد التصوير بإضاءة أفضل ',
      ),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [
      (license, 'الصورة غير واضحة: أعد التصوير بإضاءة أفضل'),
    ]);
  });

  test('with «أخرى» (no reason) the details are the whole note', () async {
    final result = await useCase(
      const AdminReviewRejection(target: license, details: ' الختم غير ظاهر '),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [(license, 'الختم غير ظاهر')]);
  });

  test('a listed reason needs no details', () async {
    final result = await useCase(
      const AdminReviewRejection(
        target: license,
        reason: 'المستند منتهي الصلاحية',
        details: '',
      ),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [(license, 'المستند منتهي الصلاحية')]);
  });

  test('a deed is rejected the same way', () async {
    final result = await useCase(
      const AdminReviewRejection(
        target: deed,
        reason: 'المستند لا يطابق بيانات المنشأة',
        details: '',
      ),
    );

    expect(result, isA<Success<void>>());
    expect(repository.rejected, [(deed, 'المستند لا يطابق بيانات المنشأة')]);
  });

  test('«أخرى» without details is refused', () async {
    final result = await useCase(
      const AdminReviewRejection(target: license, details: '  '),
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
