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
    super.ownerId,
    required super.offerCount,
    super.ownerAvatarUrl,
    super.budget,
    super.district,
    super.imageUrl,
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

    final rawImageUrl =
        json['image_url'] as String? ??
        json['imageUrl'] as String? ??
        json['photo_url'] as String? ??
        json['photoUrl'] as String? ??
        json['image'] as String? ??
        json['photo'] as String?;

    String? imageUrl = rawImageUrl?.trim();
    if ((imageUrl == null || imageUrl.isEmpty) && json['photo_paths'] is List) {
      final list = (json['photo_paths'] as List)
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (list.isNotEmpty &&
          (list.first.startsWith('http://') ||
              list.first.startsWith('https://'))) {
        imageUrl = list.first;
      }
    }

    final rawAvatarUrl =
        json['owner_avatar_url'] as String? ??
        json['ownerAvatarUrl'] as String?;
    final avatarPath = json['owner_avatar_path'] as String?;
    final ownerAvatarUrl =
        rawAvatarUrl?.trim() ??
        (avatarPath != null &&
                avatarPath.trim().isNotEmpty &&
                avatarPath.trim().startsWith('http')
            ? avatarPath.trim()
            : null);

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
      imageUrl: imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null,
      createdAt: createdAt,
      ownerName: json['owner_name'] as String? ?? '',
      ownerId: json['owner_id'] as String?,
      ownerAvatarUrl: ownerAvatarUrl,
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
