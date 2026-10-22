import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_assign_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_close_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_get_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_remove_reported_listing_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_suspend_reported_user_use_case.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_report_details_bloc.dart';

import '../../../../../helpers/fake_admin_reports_repository.dart';

void main() {
  final report = AdminReport(
    id: 'r-1',
    type: ReportType.fraud,
    status: ReportStatus.open,
    description: 'الإعلان يبيع أسمنتًا بسعر وهمي',
    target: AdminReportTarget.marketplaceItem,
    targetId: 'i-1',
    createdAt: DateTime.utc(2026, 10, 18, 20),
  );

  late FakeAdminReportsRepository repository;

  AdminReportDetailsBloc buildBloc() => AdminReportDetailsBloc(
    AdminGetReportUseCase(repository),
    AdminAssignReportUseCase(repository),
    AdminCloseReportUseCase(repository),
    AdminRemoveReportedListingUseCase(repository),
    AdminSuspendReportedUserUseCase(repository),
  );

  /// A bloc that has loaded [report].
  Future<AdminReportDetailsBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const AdminReportDetailsFetched('r-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == AdminReportDetailsStatus.success,
    );
    return bloc;
  }

  setUp(
    () =>
        repository = FakeAdminReportsRepository()
          ..reportsResult = Success([report]),
  );

  test('loads the ticket', () async {
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminReportDetailsState>().having(
          (s) => s.status,
          'status',
          AdminReportDetailsStatus.loading,
        ),
        isA<AdminReportDetailsState>()
            .having((s) => s.status, 'status', AdminReportDetailsStatus.success)
            .having((s) => s.report, 'report', report),
      ]),
    );
    bloc.add(const AdminReportDetailsFetched('r-1'));
    await states;
    await bloc.close();
  });

  test('a ticket that does not exist is not found', () async {
    final bloc = buildBloc()..add(const AdminReportDetailsFetched('r-9'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminReportDetailsStatus.failure,
    );
    expect(state.report, isNull);
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('assigning reads the ticket again', () async {
    final bloc = await loadedBloc();
    final reads = repository.reads;
    final assigned = AdminReport(
      id: 'r-1',
      type: ReportType.fraud,
      status: ReportStatus.inReview,
      isAssignedToMe: true,
      createdAt: DateTime.utc(2026, 10, 18, 20),
    );
    repository.reportResult = Success(assigned);

    bloc.add(const AdminReportDetailsAssigned());
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls, ['assign r-1']);
    expect(repository.reads, reads + 1);
    expect(state.report, assigned);
    expect(state.isBusy, isFalse);
    expect(state.message?.key, 'reports.assigned');
    await bloc.close();
  });

  test('closing sends the answer, and says which one happened', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReportDetailsClosed(
        status: ReportStatus.dismissed,
        note: 'السعر حقيقي',
      ),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls, ['close r-1 dismissed: السعر حقيقي']);
    expect(state.message?.key, 'reports.dismissed');
    await bloc.close();
  });

  test('an empty answer is refused before anything is sent', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReportDetailsClosed(status: ReportStatus.resolved, note: ' '),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls, isEmpty);
    expect(state.message?.key, 'reports.note_required');
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });

  test('removing the listing resolves the ticket with the reason', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReportDetailsListingRemoved(itemId: 'i-1', reason: 'مضلل'),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls, ['remove i-1: مضلل', 'close r-1 resolved: مضلل']);
    expect(state.message?.key, 'reports.listing_removed');
    await bloc.close();
  });

  test('suspending the user says so', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReportDetailsUserSuspended(userId: 'u-9', reason: 'مسيء'),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(repository.calls.first, 'suspend u-9: مسيء');
    expect(state.message?.key, 'reports.user_suspended');
    await bloc.close();
  });

  test('a failed action shows its error and keeps the ticket', () async {
    final bloc = await loadedBloc();
    // E.g. another admin closed it meanwhile.
    repository.actionResult = const Failed(NotFoundFailure());

    bloc.add(const AdminReportDetailsAssigned());
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.report, report);
    expect(state.isBusy, isFalse);
    expect(state.message?.key, 'errors.not_found');
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });
}
