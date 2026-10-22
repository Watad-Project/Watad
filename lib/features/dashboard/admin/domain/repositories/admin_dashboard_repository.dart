import 'package:watad/core/error/result.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';

abstract interface class AdminDashboardRepository {
  /// The numbers as they are now; [NotFoundFailure] for a user who isn't an
  /// admin (the view returns them no row).
  Future<Result<AdminDashboardStats>> getStats();
}
