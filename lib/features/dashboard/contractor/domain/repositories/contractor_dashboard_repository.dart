import 'package:watad/core/error/result.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';

/// Repository interface for contractor dashboard operations.
abstract interface class ContractorDashboardRepository {
  Future<Result<ContractorDashboardRawData>> getDashboardRawData();
}
