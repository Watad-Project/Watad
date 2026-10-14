import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_offer.dart';

class ContractorDashboardOfferModel extends ContractorDashboardOffer {
  const ContractorDashboardOfferModel({
    required super.id,
    required super.projectId,
    required super.projectTitle,
    required super.amount,
    required super.status,
    required super.createdAt,
  });

  factory ContractorDashboardOfferModel.fromJson(Map<String, dynamic> json) {
    final amountNum = json['amount'] as num? ?? 0;
    return ContractorDashboardOfferModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      projectTitle: json['project_title'] as String? ?? '',
      amount: Money.fromJson(amountNum),
      status: OfferStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
