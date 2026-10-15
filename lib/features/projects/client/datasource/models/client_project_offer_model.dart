import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

class ClientProjectOfferModel extends ClientProjectOffer {
  const ClientProjectOfferModel({
    required super.id,
    required super.projectId,
    required super.amount,
    required super.status,
    required super.createdAt,
    required super.contractorName,
    required super.isContractorVerified,
    super.contractorRating,
    super.durationMonths,
    super.message,
  });

  /// Maps the columns selected in ClientProjectsRemoteDataSourceImpl.
  factory ClientProjectOfferModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] as num;
    final rating = json['contractor_rating'] as num?;
    return ClientProjectOfferModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      amount: Money.fromJson(amount),
      status: OfferStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      contractorName: json['contractor_name'] as String? ?? '',
      contractorRating: rating?.toDouble(),
      isContractorVerified: json['is_contractor_verified'] as bool? ?? false,
      durationMonths: json['duration_months'] as int?,
      message: json['message'] as String?,
    );
  }
}
