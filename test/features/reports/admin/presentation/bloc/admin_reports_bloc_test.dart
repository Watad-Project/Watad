import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_status_filter.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_type_filter.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_assign_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_close_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_get_reports_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_remove_reported_listing_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_suspend_reported_user_use_case.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';

import '../../../../../helpers/fake_admin_reports_repository.dart';

void main() {
  final open = AdminReport(
    id: 'r-1',
    type: ReportType.paymentIssue,
    status: ReportStatus.open,
    target: AdminReportTarget.order,
    targetId: 'o-1',
    reporterName: 'عبدالله الحربي',
    createdAt: DateTime.utc(2026, 10, 18, 20),
  );
  final inReview = AdminReport(
    id: 'r-1',
    type: ReportType.paymentIssue,
    status: ReportStatus.inReview,
    target: AdminReportTarget.order,
    targetId: 'o-1',
    reporterName: 'عبدالله الحربي',
    createdAt: DateTime.utc(2026, 10, 18, 20),
  );

  late FakeAdminReportsRepository repository;

  AdminReportsBloc buildBloc() => AdminReportsBloc(
    AdminGetReportsUseCase(repository),
    AdminAssignReportUseCase(repository),
    AdminRemoveReportedListingUseCase(repository),
    AdminSuspendReportedUserUseCase(repository),
    AdminCloseReportUseCase(repository),
  );

  /// A bloc that has loaded [open].
  Future<AdminReportsBloc> loadedBloc() async {
    repository.reportsResult = Success([open]);
    final bloc = buildBloc()..add(const AdminReportsFetched());
    await bloc.stream.firstWhere((s) => s.status == AdminReportsStatus.success);
    return bloc;
  }

  setUp(() => repository = FakeAdminReportsRepository());

  test('loads the reports', () async {
    repository.reportsResult = Success([open]);
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminReportsState>().having(
          (s) => s.status,
          'status',
          AdminReportsStatus.loading,
        ),
        isA<AdminReportsState>()
            .having((s) => s.status, 'status', AdminReportsStatus.success)
            .having((s) => s.reports, 'reports', [open]),
      ]),
    );
    bloc.add(const AdminReportsFetched());
    await states;
    await bloc.close();
  });

  test('shows the failure when the reports cannot load', () async {
    repository.reportsResult = const Failed(PermissionFailure());
    final bloc = buildBloc()..add(const AdminReportsFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == AdminReportsStatus.failure,
    );
    expect(state.failure, isA<PermissionFailure>());
    await bloc.close();
  });

  test(
    'assigning reads the reports again, with the status from the server',
    () async {
      final bloc = await loadedBloc();
      repository.reportsResult = Success([inReview]);

      bloc.add(const AdminReportAssigned('r-1'));
      final state = await bloc.stream.firstWhere((s) => s.message != null);
      expect(repository.calls, ['assign r-1']);
      expect(repository.reads, 2);
      expect(state.reports.single.status, ReportStatus.inReview);
      expect(state.busyReportId, isNull);
      expect(state.message?.key, 'reports.assigned');
      expect(state.message?.isError, isFalse);
      await bloc.close();
    },
  );

  test(
    'removing a listing resolves the report and refreshes the list',
    () async {
      final bloc = await loadedBloc();
      repository.reportsResult = const Success([]);

      bloc.add(
        const AdminReportListingRemoved(
          AdminReportDecision(
            reportId: 'r-1',
            subjectId: 'i-1',
            reason: 'مضلل',
          ),
        ),
      );
      final state = await bloc.stream.firstWhere((s) => s.message != null);
      expect(repository.calls, [
        'remove i-1: مضلل',
        'close r-1 resolved: مضلل',
      ]);
      expect(state.reports, isEmpty);
      expect(state.message?.key, 'reports.listing_removed');
      await bloc.close();
    },
  );

  test('suspending a user says so', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReportUserSuspended(
        AdminReportDecision(reportId: 'r-1', subjectId: 'u-9', reason: 'مسيء'),
      ),
    );
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'reports.user_suspended');
    await bloc.close();
  });

  test('dismissing and closing say which one happened', () async {
    final bloc = await loadedBloc();

    bloc.add(
      const AdminReportClosed(
        AdminReportClosure(
          reportId: 'r-1',
          status: ReportStatus.dismissed,
          note: 'لا مخالفة',
        ),
      ),
    );
    var state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.message?.key, 'reports.dismissed');

    bloc.add(
      const AdminReportClosed(
        AdminReportClosure(
          reportId: 'r-1',
          status: ReportStatus.resolved,
          note: 'تم الحل',
        ),
      ),
    );
    state = await bloc.stream.firstWhere(
      (s) => s.message?.key == 'reports.closed',
    );
    expect(repository.calls, [
      'close r-1 dismissed: لا مخالفة',
      'close r-1 resolved: تم الحل',
    ]);
    await bloc.close();
  });

  test('a failed action shows its error and keeps the report', () async {
    final bloc = await loadedBloc();
    repository.actionResult = const Failed(NotFoundFailure());

    bloc.add(const AdminReportAssigned('r-1'));
    final state = await bloc.stream.firstWhere((s) => s.message != null);
    expect(state.reports, [open]);
    expect(state.busyReportId, isNull);
    expect(state.message?.key, 'errors.not_found');
    expect(state.message?.isError, isTrue);
    await bloc.close();
  });

  test('the chips and the type show only their tickets, with counts', () async {
    final mine = AdminReport(
      id: 'r-2',
      type: ReportType.fraud,
      status: ReportStatus.inReview,
      isAssignedToMe: true,
      createdAt: DateTime.utc(2026, 10, 19),
    );
    final closedFirst = AdminReport(
      id: 'r-3',
      type: ReportType.technicalIssue,
      status: ReportStatus.resolved,
      createdAt: DateTime.utc(2026, 10, 20),
      resolvedAt: DateTime.utc(2026, 10, 20, 1),
    );
    final closedLast = AdminReport(
      id: 'r-4',
      type: ReportType.spam,
      status: ReportStatus.dismissed,
      createdAt: DateTime.utc(2026, 10, 17),
      resolvedAt: DateTime.utc(2026, 10, 21),
    );
    repository.reportsResult = Success([closedFirst, mine, open, closedLast]);
    final bloc = buildBloc()..add(const AdminReportsFetched());
    final loaded = await bloc.stream.firstWhere(
      (s) => s.status == AdminReportsStatus.success,
    );
    // It opens on «مفتوحة», all types.
    expect(loaded.visibleReports, [open]);
    expect(loaded.countOf(AdminReportsStatusFilter.open), 1);
    expect(loaded.countOf(AdminReportsStatusFilter.inReview), 1);
    expect(loaded.countOf(AdminReportsStatusFilter.assignedToMe), 1);
    expect(loaded.countOf(AdminReportsStatusFilter.closed), 2);

    bloc.add(
      const AdminReportsStatusFilterChanged(AdminReportsStatusFilter.closed),
    );
    var state = await bloc.stream.first;
    // By when they were closed, the latest first.
    expect(state.visibleReports, [closedLast, closedFirst]);

    bloc.add(
      const AdminReportsTypeFilterChanged(AdminReportsTypeFilter.support),
    );
    state = await bloc.stream.first;
    expect(state.visibleReports, [closedFirst]);
    expect(state.countOf(AdminReportsStatusFilter.open), 1);
    expect(state.countOf(AdminReportsStatusFilter.assignedToMe), 0);

    bloc.add(
      const AdminReportsStatusFilterChanged(
        AdminReportsStatusFilter.assignedToMe,
      ),
    );
    bloc.add(
      const AdminReportsTypeFilterChanged(AdminReportsTypeFilter.moderation),
    );
    state = await bloc.stream.elementAt(1);
    expect(state.visibleReports, [mine]);

    // A reload keeps the chip and the type.
    bloc.add(const AdminReportsFetched());
    state = await bloc.stream.firstWhere(
      (s) => s.status == AdminReportsStatus.success,
    );
    expect(state.statusFilter, AdminReportsStatusFilter.assignedToMe);
    expect(state.typeFilter, AdminReportsTypeFilter.moderation);
    await bloc.close();
  });
}
