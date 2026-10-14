import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';

/// An offer sent by a contractor on a client's project.
class ClientProjectOffer {
  const ClientProjectOffer({
    required this.id,
    required this.projectId,
    required this.contractorName,
    required this.contractorRating,
    required this.isContractorVerified,
    required this.amount,
    required this.durationMonths,
    required this.status,
    required this.createdAt,
    this.message,
    this.contractorAvatarUrl,
    this.contractorId,
  });

  final String id;
  final String projectId;
  final String contractorName;
  final double contractorRating;
  final bool isContractorVerified;
  final Money amount;
  final int durationMonths;
  final OfferStatus status;
  final DateTime createdAt;
  final String? message;
  final String? contractorAvatarUrl;
  final String? contractorId;
}
