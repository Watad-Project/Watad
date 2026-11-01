import 'package:watad/features/profile/shared/datasource/models/profile_rating_model.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';

class PublicProfileModel extends PublicProfile {
  const PublicProfileModel({
    required super.id,
    required super.displayName,
    required super.isDeleted,
    required super.isBusiness,
    required super.isVerifiedBusiness,
    required super.rating,
    required super.isOnline,
    required super.isMe,
    super.avatarUrl,
    super.memberSince,
    super.companyName,
    super.specialty,
    super.lastSeenAt,
  });

  /// Maps the `v_public_profiles` columns selected in
  /// ProfileRemoteDataSourceImpl, plus `avatar_url` (the photo's public URL)
  /// and `is_me`, which the data source adds.
  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    final memberSince = json['member_since'] as String?;
    final lastSeenAt = json['last_seen_at'] as String?;
    return PublicProfileModel(
      id: json['id'] as String,
      displayName: (json['display_name'] as String?)?.trim() ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      memberSince: memberSince == null ? null : DateTime.parse(memberSince),
      isBusiness: json['is_business'] as bool? ?? false,
      companyName: json['company_name'] as String?,
      specialty: json['specialized_field'] as String?,
      isVerifiedBusiness: json['is_verified_business'] as bool? ?? false,
      rating: ProfileRatingModel.fromJson(json),
      lastSeenAt: lastSeenAt == null ? null : DateTime.parse(lastSeenAt),
      isOnline: json['is_online'] as bool? ?? false,
      isMe: json['is_me'] as bool? ?? false,
    );
  }
}
