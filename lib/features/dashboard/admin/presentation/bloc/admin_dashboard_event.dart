part of 'admin_dashboard_bloc.dart';

sealed class AdminDashboardEvent {
  const AdminDashboardEvent();
}

/// Read the numbers: each time the tab shows, on pull to refresh, on retry
/// and back from a page the dashboard opened.
final class AdminDashboardFetched extends AdminDashboardEvent {
  const AdminDashboardFetched();
}
