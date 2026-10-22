part of 'admin_dashboard_bloc.dart';

enum AdminDashboardStatus { initial, loading, success, failure }

final class AdminDashboardState {
  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.section = AdminDashboardSection.waiting,
    this.stats,
    this.failure,
  });

  final AdminDashboardStatus status;

  /// The selected chip; it opens on what waits for review.
  final AdminDashboardSection section;

  /// The last numbers read; null until the first read succeeds.
  final AdminDashboardStats? stats;

  /// Why the numbers couldn't be read.
  final Failure? failure;

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    AdminDashboardSection? section,
    AdminDashboardStats? Function()? stats,
    Failure? Function()? failure,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      section: section ?? this.section,
      stats: stats == null ? this.stats : stats(),
      failure: failure == null ? this.failure : failure(),
    );
  }
}
