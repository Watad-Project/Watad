import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';

/// An offer submitted by a contractor for a client's project: a
/// `v_project_offers` row.
class ClientProjectOffer {
  const ClientProjectOffer({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.contractorName,
    required this.isContractorVerified,
    this.contractorRating,
    this.durationMonths,
    this.message,
  });

  final String id;
  final String projectId;
  final Money amount;
  final OfferStatus status;
  final DateTime createdAt;
  final String contractorName;
  final bool isContractorVerified;
  final double? contractorRating;
  final int? durationMonths;
  final String? message;
}
