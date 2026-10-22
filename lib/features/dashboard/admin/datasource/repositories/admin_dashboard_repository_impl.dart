import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/dashboard/admin/datasource/remote/admin_dashboard_remote_data_source.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/domain/repositories/admin_dashboard_repository.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  const AdminDashboardRepositoryImpl(this._remote);

  final AdminDashboardRemoteDataSource _remote;

  @override
  Future<Result<AdminDashboardStats>> getStats() =>
      guardSupabaseCall(_remote.getStats);
}
