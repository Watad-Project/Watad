import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_closure.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_decision.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_assign_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_close_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_get_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_remove_reported_listing_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_suspend_reported_user_use_case.dart';

part 'admin_report_details_event.dart';
part 'admin_report_details_state.dart';

/// One ticket and everything an admin does on it. After every action the
/// ticket is read again, so its status, assignee and note come from the
/// server.
class AdminReportDetailsBloc
    extends Bloc<AdminReportDetailsEvent, AdminReportDetailsState> {
  AdminReportDetailsBloc(
    this._getReport,
    this._assign,
    this._close,
    this._removeListing,
    this._suspendUser,
  ) : super(const AdminReportDetailsState()) {
    on<AdminReportDetailsFetched>(_onFetched);
    on<AdminReportDetailsAssigned>(
      (event, emit) =>
          _act(emit, action: _assign.call, successKey: 'reports.assigned'),
    );
    on<AdminReportDetailsClosed>(
      (event, emit) => _act(
        emit,
        action: (id) => _close(
          AdminReportClosure(
            reportId: id,
            status: event.status,
            note: event.note,
          ),
        ),
        successKey: event.status == ReportStatus.dismissed
            ? 'reports.dismissed'
            : 'reports.closed',
      ),
    );
    on<AdminReportDetailsListingRemoved>(
      (event, emit) => _act(
        emit,
        action: (id) => _removeListing(
          AdminReportDecision(
            reportId: id,
            subjectId: event.itemId,
            reason: event.reason,
          ),
        ),
        successKey: 'reports.listing_removed',
      ),
    );
    on<AdminReportDetailsUserSuspended>(
      (event, emit) => _act(
        emit,
        action: (id) => _suspendUser(
          AdminReportDecision(
            reportId: id,
            subjectId: event.userId,
            reason: event.reason,
          ),
        ),
        successKey: 'reports.user_suspended',
      ),
    );
  }

  final AdminGetReportUseCase _getReport;
  final AdminAssignReportUseCase _assign;
  final AdminCloseReportUseCase _close;
  final AdminRemoveReportedListingUseCase _removeListing;
  final AdminSuspendReportedUserUseCase _suspendUser;

  Future<void> _onFetched(
    AdminReportDetailsFetched event,
    Emitter<AdminReportDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminReportDetailsStatus.loading,
        reportId: event.reportId,
      ),
    );
    final result = await _getReport(event.reportId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminReportDetailsStatus.success,
            report: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminReportDetailsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  /// Runs one action on the ticket, then reads it again.
  Future<void> _act(
    Emitter<AdminReportDetailsState> emit, {
    required Future<Result<void>> Function(String reportId) action,
    required String successKey,
  }) async {
    final reportId = state.reportId;
    if (reportId == null || state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    final result = await action(reportId);
    // Also after a failure: e.g. another admin closed it meanwhile.
    final report = await _getReport(reportId);
    emit(
      state.copyWith(
        report: report is Success<AdminReport> ? () => report.data : null,
        isBusy: false,
        message: () => switch (result) {
          Success() => AdminReportDetailsMessage(successKey, isError: false),
          Failed(:final failure) => AdminReportDetailsMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }
}
