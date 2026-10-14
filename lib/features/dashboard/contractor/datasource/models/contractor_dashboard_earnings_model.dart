import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';

class ContractorDashboardEarningsModel extends ContractorDashboardEarnings {
  const ContractorDashboardEarningsModel({
    required super.thisMonthEarnings,
    required super.pendingTransfers,
  });

  factory ContractorDashboardEarningsModel.fromJson(Map<String, dynamic> json) {
    final thisMonthNum = json['this_month_earnings'] as num? ?? 0;
    final pendingNum = json['pending_transfers'] as num? ?? 0;
    return ContractorDashboardEarningsModel(
      thisMonthEarnings: Money.fromJson(thisMonthNum),
      pendingTransfers: Money.fromJson(pendingNum),
    );
  }
}
