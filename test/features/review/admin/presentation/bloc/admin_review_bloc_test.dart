import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_pending_requests_use_case.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';

void main() {
  const license = AdminReviewRequest(
    kind: AdminReviewKind.license,
    id: 'b-1',
    requesterName: 'مؤسسة البناء الحديث',
  );
  const deed = AdminReviewRequest(
    kind: AdminReviewKind.deed,
    id: 'p-1',
    requesterName: 'سالم العتيبي',
  );

  late FakeAdminReviewRepository repository;

  AdminReviewBloc buildBloc() =>
      AdminReviewBloc(AdminGetPendingRequestsUseCase(repository));

  /// A bloc that has loaded [license] and [deed].
  Future<AdminReviewBloc> loadedBloc() async {
    repository.requestsResult = const Success([license, deed]);
    final bloc = buildBloc()..add(const AdminReviewFetched());
    await bloc.stream.firstWhere((s) => s.status == AdminReviewStatus.success);
    return bloc;
  }

  setUp(() => repository = FakeAdminReviewRepository());

  test('loads licenses and deeds in the order they came', () async {
    repository.requestsResult = const Success([license, deed]);
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
            .having((s) => s.requests, 'requests', [license, deed])
            .having((s) => s.allCount, 'allCount', 2)
            .having((s) => s.licenseCount, 'licenseCount', 1)
            .having((s) => s.deedCount, 'deedCount', 1),
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

  test('each chip shows its kind', () async {
    final bloc = await loadedBloc();

    bloc.add(const AdminReviewFilterChanged(AdminReviewFilter.deed));
    expect((await bloc.stream.first).visible, [deed]);
    bloc.add(const AdminReviewFilterChanged(AdminReviewFilter.license));
    expect((await bloc.stream.first).visible, [license]);
    bloc.add(const AdminReviewFilterChanged(AdminReviewFilter.all));
    expect((await bloc.stream.first).visible, [license, deed]);
    await bloc.close();
  });

  test('a request decided on its details leaves the grid', () async {
    final bloc = await loadedBloc();

    bloc.add(AdminReviewDecided(deed.target));
    final state = await bloc.stream.first;
    expect(state.requests, [license]);
    expect(state.deedCount, 0);
    await bloc.close();
  });
}
