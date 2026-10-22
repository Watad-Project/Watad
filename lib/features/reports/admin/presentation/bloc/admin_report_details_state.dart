part of 'admin_report_details_bloc.dart';

enum AdminReportDetailsStatus { initial, loading, success, failure }

/// A message to show once after an action, as a translation key.
final class AdminReportDetailsMessage {
  const AdminReportDetailsMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminReportDetailsState {
  const AdminReportDetailsState({
    this.status = AdminReportDetailsStatus.initial,
    this.reportId,
    this.report,
    this.failure,
    this.isBusy = false,
    this.message,
  });

  final AdminReportDetailsStatus status;

  /// The ticket the page shows, from the route.
  final String? reportId;
  final AdminReport? report;

  /// Why the ticket couldn't load; [NotFoundFailure] when it doesn't exist.
  final Failure? failure;

  /// An action is being sent.
  final bool isBusy;
  final AdminReportDetailsMessage? message;

  AdminReportDetailsState copyWith({
    AdminReportDetailsStatus? status,
    String? reportId,
    AdminReport? Function()? report,
    Failure? Function()? failure,
    bool? isBusy,
    AdminReportDetailsMessage? Function()? message,
  }) {
    return AdminReportDetailsState(
      status: status ?? this.status,
      reportId: reportId ?? this.reportId,
      report: report == null ? this.report : report(),
      failure: failure == null ? this.failure : failure(),
      isBusy: isBusy ?? this.isBusy,
      message: message == null ? this.message : message(),
    );
  }
}
