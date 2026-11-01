import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';

/// What changed in the account part of the edit form (GRA-60): the name
/// and the photo, both saved to the user's `users` row.
class ProfileUserChanges {
  const ProfileUserChanges({
    this.fullName,
    this.photo = const ProfilePhotoKept(),
  });

  /// The new name, trimmed; null when it didn't change.
  final String? fullName;
  final ProfilePhotoChange photo;

  bool get isEmpty => fullName == null && photo is ProfilePhotoKept;
}
