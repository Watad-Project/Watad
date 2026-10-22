part of 'admin_reports_bloc.dart';

enum AdminReportsStatus { initial, loading, success, failure }

/// A message to show once after an action, as a translation key.
final class AdminReportsMessage {
  const AdminReportsMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminReportsState {
  const AdminReportsState({
    this.status = AdminReportsStatus.initial,
    this.reports = const [],
    this.failure,
    this.busyReportId,
    this.message,
  });

  final AdminReportsStatus status;

  /// Open and in-review reports, newest first.
  final List<AdminReport> reports;

  /// Why the reports couldn't load.
  final Failure? failure;

  /// The report whose action is being sent.
  final String? busyReportId;
  final AdminReportsMessage? message;

  AdminReportsState copyWith({
    AdminReportsStatus? status,
    List<AdminReport>? reports,
    Failure? Function()? failure,
    String? Function()? busyReportId,
    AdminReportsMessage? Function()? message,
  }) {
    return AdminReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      failure: failure == null ? this.failure : failure(),
      busyReportId: busyReportId == null ? this.busyReportId : busyReportId(),
      message: message == null ? this.message : message(),
    );
  }
}
