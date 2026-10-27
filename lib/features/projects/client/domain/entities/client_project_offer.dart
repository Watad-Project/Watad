import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';

/// A contractor's offer on one of the client's projects: a
/// `v_project_offers` row.
class ClientProjectOffer {
  const ClientProjectOffer({
    required this.id,
    required this.projectId,
    required this.providerId,
    required this.amount,
    required this.status,
    required this.providerName,
    required this.isProviderVerified,
    required this.providerRatingCount,
    required this.createdAt,
    this.providerRatingAvg,
    this.message,
  });

  final String id;
  final String projectId;

  /// The contractor's user id: who «مراسلة» opens a chat with.
  final String providerId;
  final Money amount;
  final OfferStatus status;

  /// The contractor's company.
  final String providerName;
  final bool isProviderVerified;

  /// The average of the contractor's reviews; null before the first one.
  final double? providerRatingAvg;
  final int providerRatingCount;

  /// The contractor's note, e.g. «يشمل التشطيب الخارجي».
  final String? message;
  final DateTime createdAt;
}
