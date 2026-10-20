import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_deed_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_license_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_requester.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_approve_request_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_request_details_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_details_bloc.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';

void main() {
  const licenseTarget = AdminReviewTarget(
    kind: AdminReviewKind.license,
    id: 'b-1',
  );
  const deedTarget = AdminReviewTarget(kind: AdminReviewKind.deed, id: 'p-1');
  const license = AdminLicenseDetails(
    target: licenseTarget,
    requester: AdminReviewRequester(name: 'سالم العتيبي'),
    companyName: 'مؤسسة البناء الحديث',
    crNumber: '1010123456',
    documents: [],
  );
  const deed = AdminDeedDetails(
    target: deedTarget,
    requester: AdminReviewRequester(name: 'سارة القحطاني'),
    title: 'بناء فيلا',
    deedUrl: 'https://example.supabase.co/sign/deed.pdf',
    deedPath: 'u-1/deed.pdf',
  );

  late FakeAdminReviewRepository repository;

  AdminReviewDetailsBloc buildBloc() => AdminReviewDetailsBloc(
    AdminGetRequestDetailsUseCase(repository),
    AdminApproveRequestUseCase(repository),
    AdminRejectRequestUseCase(repository),
  );

  /// A bloc that has loaded [target].
  Future<AdminReviewDetailsBloc> loadedBloc(AdminReviewTarget target) async {
    final bloc = buildBloc()..add(AdminReviewDetailsFetched(target));
    await bloc.stream.firstWhere(
      (s) => s.status == AdminReviewDetailsStatus.success,
    );
    return bloc;
  }

  setUp(() {
    repository = FakeAdminReviewRepository()
      ..details[licenseTarget] = license
      ..details[deedTarget] = deed;
  });

  test('loads the request with its requester', () async {
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminReviewDetailsState>().having(
          (s) => s.status,
          'status',
          AdminReviewDetailsStatus.loading,
        ),
        isA<AdminReviewDetailsState>()
            .having((s) => s.status, 'status', AdminReviewDetailsStatus.success)
            .having((s) => s.details, 'details', license),
      ]),
    );
    bloc.add(const AdminReviewDetailsFetched(licenseTarget));
    await states;
    await bloc.close();
  });

  test('a request another admin decided is not found', () async {
    final bloc = buildBloc()
      ..add(
        const AdminReviewDetailsFetched(
          AdminReviewTarget(kind: AdminReviewKind.deed, id: 'gone'),
        ),
      );

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminReviewDetailsStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('approving a license closes the page with its message', () async {
    final bloc = await loadedBloc(licenseTarget);

    bloc.add(const AdminReviewDetailsApproved());
    final state = await bloc.stream.firstWhere(
      (s) => s.decision == AdminReviewDecisionStatus.done,
    );
    expect(repository.approved, [licenseTarget]);
    expect(state.message?.key, 'review.approved');
    expect(state.message?.isError, isFalse);
    await bloc.close();
  });

  test('approving a deed says the project is published', () async {
    final bloc = await loadedBloc(deedTarget);

    bloc.add(const AdminReviewDetailsApproved());
    final state = await bloc.stream.firstWhere(
      (s) => s.decision == AdminReviewDecisionStatus.done,
    );
    expect(repository.approved, [deedTarget]);
    expect(state.message?.key, 'review.deed_approved');
    await bloc.close();
  });

  test('rejecting a deed sends the reason as the note', () async {
    final bloc = await loadedBloc(deedTarget);

    bloc.add(
      const AdminReviewDetailsRejected(reason: 'الصورة غير واضحة', details: ''),
    );
    final state = await bloc.stream.firstWhere(
      (s) => s.decision == AdminReviewDecisionStatus.done,
    );
    expect(repository.rejected, [(deedTarget, 'الصورة غير واضحة')]);
    expect(state.message?.key, 'review.deed_rejected');
    await bloc.close();
  });

  test('a failed decision keeps the page open with the error', () async {
    final bloc = await loadedBloc(licenseTarget);
    repository.decisionResult = const Failed(PermissionFailure());

    bloc.add(const AdminReviewDetailsApproved());
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.decision, AdminReviewDecisionStatus.idle);
    expect(state.message?.key, 'errors.permission');
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });
}
