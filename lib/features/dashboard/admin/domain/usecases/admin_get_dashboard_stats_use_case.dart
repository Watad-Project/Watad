import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/domain/repositories/admin_dashboard_repository.dart';

/// The platform's numbers, for the admin dashboard.
class AdminGetDashboardStatsUseCase
    implements UseCase<AdminDashboardStats, NoParams> {
  const AdminGetDashboardStatsUseCase(this._repository);

  final AdminDashboardRepository _repository;

  @override
  Future<Result<AdminDashboardStats>> call(NoParams params) =>
      _repository.getStats();
}
