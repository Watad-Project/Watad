import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';

/// An open project available for contractors to bid on (`v_open_projects`).
class ContractorOpenProject {
  const ContractorOpenProject({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.createdAt,
    required this.ownerName,
    required this.offerCount,
    this.budget,
    this.district,
    this.imageUrl,
    this.myOfferId,
    this.myOfferAmount,
    this.myOfferStatus,
    this.isMine = false,
  });

  final String id;
  final String title;
  final String description;
  final Money? budget;
  final String city;
  final String? district;
  final String? imageUrl;
  final DateTime createdAt;
  final String ownerName;
  final int offerCount;
  final String? myOfferId;
  final Money? myOfferAmount;
  final OfferStatus? myOfferStatus;
  final bool isMine;

  bool get hasMyOffer => myOfferId != null;

  bool get isMyOfferPending => myOfferStatus == OfferStatus.pending;
}
