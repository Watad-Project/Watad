import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_payment.dart';

class ContractorDashboardPaymentModel extends ContractorDashboardPayment {
  const ContractorDashboardPaymentModel({
    required super.amount,
    required super.status,
    super.paidAt,
  });

  factory ContractorDashboardPaymentModel.fromJson(Map<String, dynamic> json) {
    final amountNum = json['amount'] as num? ?? 0;
    final statusStr = json['status'] as String? ?? 'pending';
    final paidAtStr = json['paid_at'] as String?;

    final status = PaymentStatus.values.firstWhere(
      (e) => e.value == statusStr,
      orElse: () => PaymentStatus.pending,
    );

    return ContractorDashboardPaymentModel(
      amount: Money.fromJson(amountNum),
      status: status,
      paidAt: paidAtStr != null ? DateTime.tryParse(paidAtStr) : null,
    );
  }
}
