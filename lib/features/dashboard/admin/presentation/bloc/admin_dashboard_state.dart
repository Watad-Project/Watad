part of 'admin_dashboard_bloc.dart';

enum AdminDashboardStatus { initial, loading, success, failure }

final class AdminDashboardState {
  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.stats,
    this.failure,
  });

  final AdminDashboardStatus status;

  /// The last numbers read; null until the first read succeeds.
  final AdminDashboardStats? stats;

  /// Why the numbers couldn't be read.
  final Failure? failure;

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    AdminDashboardStats? Function()? stats,
    Failure? Function()? failure,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      stats: stats == null ? this.stats : stats(),
      failure: failure == null ? this.failure : failure(),
    );
  }
}
