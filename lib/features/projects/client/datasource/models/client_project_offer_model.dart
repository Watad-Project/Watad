import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

class ClientProjectOfferModel extends ClientProjectOffer {
  const ClientProjectOfferModel({
    required super.id,
    required super.projectId,
    required super.contractorName,
    required super.contractorRating,
    required super.isContractorVerified,
    required super.amount,
    required super.durationMonths,
    required super.status,
    required super.createdAt,
    super.message,
    super.contractorAvatarUrl,
    super.contractorId,
  });

  /// Maps the columns from `v_project_offers`.
  factory ClientProjectOfferModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] as num? ?? 0;
    final rawRating = json['contractor_rating'] as num?;
    final rawDuration = json['duration_months'] as int?;
    final isVerified = json['is_contractor_verified'] as bool? ?? true;

    return ClientProjectOfferModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      contractorName: json['contractor_name'] as String? ?? '',
      contractorRating: (rawRating ?? 5.0).toDouble(),
      isContractorVerified: isVerified,
      amount: Money.fromJson(rawAmount),
      durationMonths: rawDuration ?? 1,
      status: OfferStatus.fromJson(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      message: json['message'] as String?,
      contractorAvatarUrl: json['contractor_avatar_url'] as String?,
      contractorId: json['contractor_id'] as String?,
    );
  }
}
