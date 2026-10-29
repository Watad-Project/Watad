import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';

/// The signed-in user's own profile: their `v_my_profile` row (GRA-59).
class MyProfile {
  const MyProfile({
    required this.id,
    required this.fullName,
    required this.isSuspended,
    this.avatarPath,
    this.avatarUrl,
    this.suspensionReason,
    this.business,
  });

  final String id;
  final String fullName;

  /// The photo's path in the `avatars` bucket, `<user id>/<file name>`;
  /// null without a photo.
  final String? avatarPath;

  /// The photo's public URL, for `AppAvatar`; null without a photo.
  final String? avatarUrl;

  /// An admin suspended the account: it can still read, but not post or
  /// edit anything.
  final bool isSuspended;

  /// Why, in the admin's words; set while [isSuspended].
  final String? suspensionReason;

  /// The user's business; null for a client.
  final MyProfileBusiness? business;
}
