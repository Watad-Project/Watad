import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';

class ClientProjectOfferModel extends ClientProjectOffer {
  const ClientProjectOfferModel({
    required super.id,
    required super.projectId,
    required super.providerId,
    required super.amount,
    required super.status,
    required super.providerName,
    required super.isProviderVerified,
    required super.providerRatingCount,
    required super.createdAt,
    super.providerRatingAvg,
    super.message,
  });

  /// Maps the `v_project_offers` columns selected in
  /// ClientProjectsRemoteDataSourceImpl.
  factory ClientProjectOfferModel.fromJson(Map<String, dynamic> json) {
    final message = (json['message'] as String?)?.trim();
    return ClientProjectOfferModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      providerId: json['provider_id'] as String,
      amount: Money.fromJson(json['amount'] as num),
      status: OfferStatus.fromJson(json['status'] as String),
      providerName: json['provider_company_name'] as String? ?? '',
      isProviderVerified: json['provider_is_verified'] as bool? ?? false,
      providerRatingAvg: (json['provider_rating_avg'] as num?)?.toDouble(),
      providerRatingCount: json['provider_rating_count'] as int? ?? 0,
      message: message == null || message.isEmpty ? null : message,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
