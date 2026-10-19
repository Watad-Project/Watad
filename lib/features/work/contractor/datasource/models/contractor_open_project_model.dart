import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';

class ContractorOpenProjectModel extends ContractorOpenProject {
  const ContractorOpenProjectModel({
    required super.id,
    required super.title,
    required super.description,
    required super.city,
    required super.createdAt,
    required super.ownerName,
    required super.offerCount,
    super.budget,
    super.district,
    super.myOfferId,
    super.myOfferAmount,
    super.myOfferStatus,
    super.isMine,
  });

  factory ContractorOpenProjectModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] as String?;
    final createdAt = createdAtStr != null
        ? (DateTime.tryParse(createdAtStr) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final statusStr = json['my_offer_status'] as String?;
    final myOfferStatus = statusStr != null
        ? OfferStatus.values.firstWhere(
            (e) => e.value == statusStr,
            orElse: () => OfferStatus.pending,
          )
        : null;

    return ContractorOpenProjectModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      budget: switch (json['budget']) {
        final num value => Money.fromJson(value),
        _ => null,
      },
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      createdAt: createdAt,
      ownerName: json['owner_name'] as String? ?? '',
      offerCount: (json['offer_count'] as num?)?.toInt() ?? 0,
      myOfferId: json['my_offer_id'] as String?,
      myOfferAmount: switch (json['my_offer_amount']) {
        final num value => Money.fromJson(value),
        _ => null,
      },
      myOfferStatus: myOfferStatus,
      isMine: json['is_mine'] as bool? ?? false,
    );
  }
}
