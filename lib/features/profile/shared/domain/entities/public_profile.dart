import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';

/// What anyone sees about a user (GRA-58): a `v_public_profiles` row.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.displayName,
    required this.isDeleted,
    required this.isBusiness,
    required this.isVerifiedBusiness,
    required this.rating,
    required this.isOnline,
    required this.isMe,
    this.avatarUrl,
    this.memberSince,
    this.companyName,
    this.specialty,
    this.lastSeenAt,
  });

  final String id;

  /// The company's name for a business, the person's name otherwise.
  final String displayName;
  final String? avatarUrl;

  /// A closed account: «حساب محذوف», and nothing to do with it.
  final bool isDeleted;
  final DateTime? memberSince;
  final bool isBusiness;
  final String? companyName;

  /// The business's specialty as it was saved.
  final String? specialty;
  final bool isVerifiedBusiness;
  final ProfileRating rating;
  final DateTime? lastSeenAt;
  final bool isOnline;

  /// The signed-in user's own profile.
  final bool isMe;
}
