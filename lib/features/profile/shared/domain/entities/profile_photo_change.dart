import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';

/// What «حفظ» does with the profile photo (GRA-60).
sealed class ProfilePhotoChange {
  const ProfilePhotoChange();
}

/// The photo stays as it is.
final class ProfilePhotoKept extends ProfilePhotoChange {
  const ProfilePhotoKept();
}

/// [photo] replaces the photo, if there was one.
final class ProfilePhotoReplaced extends ProfilePhotoChange {
  const ProfilePhotoReplaced(this.photo);

  final ProfilePhoto photo;
}

/// The photo goes: the default avatar shows instead.
final class ProfilePhotoRemoved extends ProfilePhotoChange {
  const ProfilePhotoRemoved();
}
