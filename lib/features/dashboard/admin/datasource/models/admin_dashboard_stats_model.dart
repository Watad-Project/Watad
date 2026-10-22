import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';

class AdminDashboardStatsModel extends AdminDashboardStats {
  const AdminDashboardStatsModel({
    required super.activeUsers,
    required super.clients,
    required super.businesses,
    required super.verifiedBusinesses,
    required super.projects,
    required super.draftProjects,
    required super.openProjects,
    required super.inProgressProjects,
    required super.completedProjects,
    required super.cancelledProjects,
    required super.marketItems,
    required super.liveMarketItems,
    required super.pendingLicenses,
    required super.pendingDeeds,
    required super.openReports,
  });

  /// Maps the `v_admin_dashboard` row selected in
  /// AdminDashboardRemoteDataSourceImpl.
  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    int count(String column) => (json[column] as num?)?.toInt() ?? 0;
    return AdminDashboardStatsModel(
      activeUsers: count('active_users'),
      clients: count('clients'),
      businesses: count('businesses'),
      verifiedBusinesses: count('verified_businesses'),
      projects: count('projects'),
      draftProjects: count('projects_draft'),
      openProjects: count('projects_open'),
      inProgressProjects: count('projects_in_progress'),
      completedProjects: count('projects_completed'),
      cancelledProjects: count('projects_cancelled'),
      marketItems: count('market_items'),
      liveMarketItems: count('market_items_live'),
      pendingLicenses: count('pending_licenses'),
      pendingDeeds: count('pending_deeds'),
      openReports: count('open_reports'),
    );
  }
}
