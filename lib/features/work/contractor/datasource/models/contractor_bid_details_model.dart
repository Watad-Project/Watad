import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_open_project_model.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';

class ContractorBidDetailsModel extends ContractorBidDetails {
  const ContractorBidDetailsModel({
    required super.verificationStatus,
    super.project,
    super.existingOfferId,
    super.existingOfferAmount,
    super.existingOfferMessage,
    super.existingOfferStatus,
  });

  factory ContractorBidDetailsModel.fromJson(Map<String, dynamic> json) {
    final projectMap = switch (json['project']) {
      final Map<dynamic, dynamic> map => Map<String, dynamic>.from(map),
      _ => null,
    };
    final project = projectMap != null
        ? ContractorOpenProjectModel.fromJson(projectMap)
        : null;

    final verificationStatusStr =
        json['verification_status'] as String? ?? 'unverified';
    final verificationStatus = VerificationStatus.fromJson(
      verificationStatusStr,
    );

    final offerMap = switch (json['offer']) {
      final Map<dynamic, dynamic> map => Map<String, dynamic>.from(map),
      _ => null,
    };

    final offerId = (offerMap?['id'] as String?) ?? project?.myOfferId;
    final offerAmount = switch (offerMap?['amount']) {
      final num value => Money.fromJson(value),
      _ => project?.myOfferAmount,
    };
    final offerMessage = offerMap?['message'] as String?;

    final statusStr = offerMap?['status'] as String?;
    final offerStatus = statusStr != null
        ? OfferStatus.values.firstWhere(
            (e) => e.value == statusStr,
            orElse: () => OfferStatus.pending,
          )
        : project?.myOfferStatus;

    return ContractorBidDetailsModel(
      project: project,
      verificationStatus: verificationStatus,
      existingOfferId: offerId,
      existingOfferAmount: offerAmount,
      existingOfferMessage: offerMessage,
      existingOfferStatus: offerStatus,
    );
  }
}
