import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_status_filter.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_reports_type_filter.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_assign_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_close_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_get_reports_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_remove_reported_listing_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_suspend_reported_user_use_case.dart';

part 'admin_reports_event.dart';
part 'admin_reports_state.dart';

/// Every ticket an admin handles, filtered by status and type, and the
/// quick actions on them. After every action the list is read again, so
/// statuses come from the server.
class AdminReportsBloc extends Bloc<AdminReportsEvent, AdminReportsState> {
  AdminReportsBloc(
    this._getReports,
    this._assign,
    this._removeListing,
    this._suspendUser,
    this._close,
  ) : super(const AdminReportsState()) {
    on<AdminReportsFetched>(_onFetched);
    on<AdminReportsStatusFilterChanged>(
      (event, emit) => emit(state.copyWith(statusFilter: event.filter)),
    );
    on<AdminReportsTypeFilterChanged>(
      (event, emit) => emit(state.copyWith(typeFilter: event.filter)),
    );
    on<AdminReportAssigned>(
      (event, emit) => _act(
        emit,
        reportId: event.reportId,
        action: () => _assign(event.reportId),
        successKey: 'reports.assigned',
      ),
    );
    on<AdminReportListingRemoved>(
      (event, emit) => _act(
        emit,
        reportId: event.decision.reportId,
        action: () => _removeListing(event.decision),
        successKey: 'reports.listing_removed',
      ),
    );
    on<AdminReportUserSuspended>(
      (event, emit) => _act(
        emit,
        reportId: event.decision.reportId,
        action: () => _suspendUser(event.decision),
        successKey: 'reports.user_suspended',
      ),
    );
    on<AdminReportClosed>(
      (event, emit) => _act(
        emit,
        reportId: event.closure.reportId,
        action: () => _close(event.closure),
        successKey: event.closure.status == ReportStatus.dismissed
            ? 'reports.dismissed'
            : 'reports.closed',
      ),
    );
  }

  final AdminGetReportsUseCase _getReports;
  final AdminAssignReportUseCase _assign;
  final AdminRemoveReportedListingUseCase _removeListing;
  final AdminSuspendReportedUserUseCase _suspendUser;
  final AdminCloseReportUseCase _close;

  Future<void> _onFetched(
    AdminReportsFetched event,
    Emitter<AdminReportsState> emit,
  ) async {
    emit(state.copyWith(status: AdminReportsStatus.loading));
    final result = await _getReports(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminReportsStatus.success,
            reports: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminReportsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// Runs one action, then reads the reports again.
  Future<void> _act(
    Emitter<AdminReportsState> emit, {
    required String reportId,
    required Future<Result<void>> Function() action,
    required String successKey,
  }) async {
    if (state.busyReportId != null) return;
    emit(state.copyWith(busyReportId: () => reportId));
    final result = await action();
    // Also after a failure: e.g. another admin closed the report meanwhile.
    final reports = await _getReports(const NoParams());
    emit(
      state.copyWith(
        reports: reports is Success<List<AdminReport>> ? reports.data : null,
        busyReportId: () => null,
        message: () => switch (result) {
          Success() => AdminReportsMessage(successKey, isError: false),
          Failed(:final failure) => AdminReportsMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }
}
