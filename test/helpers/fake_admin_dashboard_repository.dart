import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/dashboard/admin/admin_dashboard_injection.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/domain/repositories/admin_dashboard_repository.dart';

/// Numbers that are all different, so a test can find each one.
const AdminDashboardStats fakeAdminDashboardStats = AdminDashboardStats(
  activeUsers: 1210,
  clients: 980,
  businesses: 260,
  verifiedBusinesses: 212,
  projects: 418,
  draftProjects: 31,
  openProjects: 57,
  inProgressProjects: 96,
  completedProjects: 219,
  cancelledProjects: 15,
  marketItems: 640,
  liveMarketItems: 588,
  pendingLicenses: 7,
  pendingDeeds: 4,
  openReports: 5,
  onlineUsers: 37,
);

/// A hand-written [AdminDashboardRepository]: it answers with the result you
/// set and counts the reads (APP_ARCHITECTURE.md §16).
class FakeAdminDashboardRepository implements AdminDashboardRepository {
  Result<AdminDashboardStats> statsResult = const Success(
    fakeAdminDashboardStats,
  );

  /// How many times the numbers were read.
  int reads = 0;

  @override
  Future<Result<AdminDashboardStats>> getStats() async {
    reads++;
    return statsResult;
  }
}

/// For tests that open the admin's navigation (its «الرئيسية» tab) or the
/// dashboard route: the real registrations, with [repository] in place of
/// Supabase. Reset getIt after the test.
void registerFakeAdminDashboard(FakeAdminDashboardRepository repository) {
  registerAdminDashboardDependencies(getIt);
  getIt
    ..unregister<AdminDashboardRepository>()
    ..registerSingleton<AdminDashboardRepository>(repository);
}
