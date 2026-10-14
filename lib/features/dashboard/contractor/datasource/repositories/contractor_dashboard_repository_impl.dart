import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/dashboard/contractor/datasource/remote/contractor_dashboard_remote_data_source.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';

class ContractorDashboardRepositoryImpl
    implements ContractorDashboardRepository {
  const ContractorDashboardRepositoryImpl(this._remote);

  final ContractorDashboardRemoteDataSource _remote;

  @override
  Future<Result<ContractorDashboardData>> getDashboardData() =>
      guardSupabaseCall(_remote.getDashboardData);
}
