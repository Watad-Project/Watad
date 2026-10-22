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
    this.statusFilter = AdminReportsStatusFilter.open,
    this.typeFilter = AdminReportsTypeFilter.all,
    this.failure,
    this.busyReportId,
    this.message,
  });

  final AdminReportsStatus status;

  /// Every ticket, closed ones included, newest first.
  final List<AdminReport> reports;

  /// The selected status chip and type.
  final AdminReportsStatusFilter statusFilter;
  final AdminReportsTypeFilter typeFilter;

  /// Why the tickets couldn't load.
  final Failure? failure;

  /// The ticket whose action is being sent.
  final String? busyReportId;
  final AdminReportsMessage? message;

  /// The tickets of the selected chip and type: newest first, closed ones
  /// by when they were closed.
  List<AdminReport> get visibleReports {
    final visible = [
      for (final report in reports)
        if (statusFilter.matches(report) && typeFilter.matches(report)) report,
    ];
    if (statusFilter == AdminReportsStatusFilter.closed) {
      visible.sort(
        (a, b) => (b.resolvedAt ?? b.createdAt).compareTo(
          a.resolvedAt ?? a.createdAt,
        ),
      );
    }
    return visible;
  }

  /// The number on [filter]'s chip, within the selected type.
  int countOf(AdminReportsStatusFilter filter) => reports
      .where((report) => filter.matches(report) && typeFilter.matches(report))
      .length;

  AdminReportsState copyWith({
    AdminReportsStatus? status,
    List<AdminReport>? reports,
    AdminReportsStatusFilter? statusFilter,
    AdminReportsTypeFilter? typeFilter,
    Failure? Function()? failure,
    String? Function()? busyReportId,
    AdminReportsMessage? Function()? message,
  }) {
    return AdminReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      failure: failure == null ? this.failure : failure(),
      busyReportId: busyReportId == null ? this.busyReportId : busyReportId(),
      message: message == null ? this.message : message(),
    );
  }
}
