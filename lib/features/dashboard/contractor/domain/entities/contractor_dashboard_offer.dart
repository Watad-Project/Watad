import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';

/// A sent offer for the contractor dashboard.
class ContractorDashboardOffer {
  const ContractorDashboardOffer({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String projectTitle;
  final Money amount;
  final OfferStatus status;
  final DateTime createdAt;
}
