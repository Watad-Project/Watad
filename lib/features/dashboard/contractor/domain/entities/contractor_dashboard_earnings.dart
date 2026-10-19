import 'package:watad/core/utils/money.dart';

/// Earnings summary for the contractor dashboard.
class ContractorDashboardEarnings {
  const ContractorDashboardEarnings({
    required this.thisMonthEarnings,
    required this.pendingTransfers,
  });

  final Money thisMonthEarnings;
  final Money pendingTransfers;
}
