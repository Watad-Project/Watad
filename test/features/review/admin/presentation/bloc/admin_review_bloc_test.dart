import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_rejection.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_approve_request_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_pending_requests_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';

void main() {
  const first = AdminReviewRequest(
    businessId: 'b-1',
    companyName: 'مؤسسة البناء الحديث',
    documentCount: 1,
  );
  const second = AdminReviewRequest(
    businessId: 'b-2',
    companyName: 'Watad Builders',
    documentCount: 2,
  );

  late FakeAdminReviewRepository repository;

  AdminReviewBloc buildBloc() => AdminReviewBloc(
    AdminGetPendingRequestsUseCase(repository),
    AdminApproveRequestUseCase(repository),
    AdminRejectRequestUseCase(repository),
  );

  /// A bloc that has loaded [first] and [second].
  Future<AdminReviewBloc> loadedBloc() async {
    repository.requestsResult = const Success([first, second]);
    final bloc = buildBloc()..add(const AdminReviewFetched());
    await bloc.stream.firstWhere((s) => s.status == AdminReviewStatus.success);
    return bloc;
  }

  setUp(() => repository = FakeAdminReviewRepository());

  test('loads the pending requests in the order they came', () async {
    repository.requestsResult = const Success([first, second]);
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminReviewState>().having(
          (s) => s.status,
          'status',
          AdminReviewStatus.loading,
        ),
        isA<AdminReviewState>()
            .having((s) => s.status, 'status', AdminReviewStatus.success)
            .having((s) => s.requests, 'requests', [first, second])
            .having((s) => s.allCount, 'allCount', 2),
      ]),
    );
    bloc.add(const AdminReviewFetched());
    await states;
    await bloc.close();
  });

  test('shows the failure when the queue cannot load', () async {
    repository.requestsResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const AdminReviewFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminReviewStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('the deed chip is empty: deeds have no backend yet', () async {
    final bloc = await loadedBloc();

    bloc.add(const AdminReviewFilterChanged(AdminReviewFilter.deed));
    final state = await bloc.stream.first;
    expect(state.visible, isEmpty);
    expect(state.licenseCount, 2);
    await bloc.close();
  });

  test('an approved request leaves the list with a success message', () async {
    final bloc = await loadedBloc();

    bloc.add(const AdminReviewApproved('b-1'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.approved, ['b-1']);
    expect(state.requests, [second]);
    expect(state.busyBusinessId, isNull);
    expect(state.message?.key, 'review.approved');
    expect(state.message?.isError, isFalse);
    await bloc.close();
  });

  test('a rejected request leaves the list with its note sent', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReviewRejected(
        AdminReviewRejection(
          businessId: 'b-2',
          reason: 'المستند منتهي الصلاحية',
          details: 'ارفع رخصة سارية',
        ),
      ),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.rejected, [
      ('b-2', 'المستند منتهي الصلاحية: ارفع رخصة سارية'),
    ]);
    expect(state.requests, [first]);
    expect(state.message?.key, 'review.rejected');
    await bloc.close();
  });

  test('a failed decision keeps the request and shows the error', () async {
    final bloc = await loadedBloc();
    repository.decisionResult = const Failed(PermissionFailure());

    bloc.add(const AdminReviewApproved('b-1'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.requests, [first, second]);
    expect(state.busyBusinessId, isNull);
    expect(state.message?.key, 'errors.permission');
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });
}
