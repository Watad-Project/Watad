import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';

/// Fetches the aggregated dashboard data for the signed-in contractor.
class ContractorGetDashboardDataUseCase
    implements UseCase<ContractorDashboardData, NoParams> {
  const ContractorGetDashboardDataUseCase(this._repository);

  final ContractorDashboardRepository _repository;

  @override
  Future<Result<ContractorDashboardData>> call(NoParams params) =>
      _repository.getDashboardData();
}
