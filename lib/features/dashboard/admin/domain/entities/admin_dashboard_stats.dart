/// The platform's numbers for the admin dashboard: the `v_admin_dashboard`
/// row.
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.activeUsers,
    required this.clients,
    required this.businesses,
    required this.verifiedBusinesses,
    required this.projects,
    required this.draftProjects,
    required this.openProjects,
    required this.inProgressProjects,
    required this.completedProjects,
    required this.cancelledProjects,
    required this.marketItems,
    required this.liveMarketItems,
    required this.pendingLicenses,
    required this.pendingDeeds,
    required this.openReports,
    required this.onlineUsers,
    required this.blockchainFailed,
    required this.blockchainPending,
  });

  /// Not deleted and not suspended, admins left out.
  final int activeUsers;

  /// Users with no business who aren't admins.
  final int clients;

  /// Registered businesses, and how many of them are verified.
  final int businesses;
  final int verifiedBusinesses;

  /// Every project, and the count of each status.
  final int projects;
  final int draftProjects;
  final int openProjects;
  final int inProgressProjects;
  final int completedProjects;
  final int cancelledProjects;

  /// Listed items, and how many are on the market now (active and not
  /// removed by an admin).
  final int marketItems;
  final int liveMarketItems;

  /// Waiting in the «التوثيق» tab.
  final int pendingLicenses;
  final int pendingDeeds;

  /// Support tickets and reports nobody has taken yet.
  final int openReports;

  /// Users with the app open now (the rule of `is_online`), admins left
  /// out.
  final int onlineUsers;

  /// Contracted projects whose blockchain sync needs a person
  /// (`v_admin_blockchain_summary.failed`).
  final int blockchainFailed;

  /// Contracted projects waiting to sync or retrying (`waiting` +
  /// `retrying`).
  final int blockchainPending;
}
