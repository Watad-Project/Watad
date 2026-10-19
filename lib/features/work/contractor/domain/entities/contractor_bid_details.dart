import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';

/// All data needed to display and interact with the contractor bid screen
/// (`/contractor/work/:projectId/bid`).
class ContractorBidDetails {
  const ContractorBidDetails({
    required this.verificationStatus,
    this.project,
    this.existingOfferId,
    this.existingOfferAmount,
    this.existingOfferMessage,
    this.existingOfferStatus,
  });

  /// Null when the project is no longer open or does not exist.
  final ContractorOpenProject? project;
  final VerificationStatus verificationStatus;
  final String? existingOfferId;
  final Money? existingOfferAmount;
  final String? existingOfferMessage;
  final OfferStatus? existingOfferStatus;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  bool get hasPendingOffer =>
      existingOfferId != null && existingOfferStatus == OfferStatus.pending;
}
