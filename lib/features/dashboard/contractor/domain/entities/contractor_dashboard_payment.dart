import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/utils/money.dart';

/// A payment row from `v_project_payments`.
class ContractorDashboardPayment {
  const ContractorDashboardPayment({
    required this.amount,
    required this.status,
    this.paidAt,
  });

  final Money amount;
  final PaymentStatus status;
  final DateTime? paidAt;
}
