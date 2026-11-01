part of 'profile_edit_bloc.dart';

sealed class ProfileEditEvent {
  const ProfileEditEvent();
}

/// The page opened, or the user tapped retry.
final class ProfileEditFetched extends ProfileEditEvent {
  const ProfileEditFetched();
}

/// The user typed in the name, the company name or the CR number.
final class ProfileEditFormChanged extends ProfileEditEvent {
  const ProfileEditFormChanged(this.draft);

  final ProfileFormDraft draft;
}

/// The contractor tapped a specialty chip: [label] is its text in the
/// app's language, or null for the specialty already saved.
final class ProfileEditSpecialtyPicked extends ProfileEditEvent {
  const ProfileEditSpecialtyPicked(this.label);

  final String? label;
}

/// The city search found the city of the place the contractor picked.
final class ProfileEditCityPicked extends ProfileEditEvent {
  const ProfileEditCityPicked(this.city);

  final String city;
}

/// A photo came from the camera or the gallery.
final class ProfileEditPhotoPicked extends ProfileEditEvent {
  const ProfileEditPhotoPicked(this.bytes);

  final Uint8List bytes;
}

/// «إزالة الصورة», confirmed.
final class ProfileEditPhotoRemoved extends ProfileEditEvent {
  const ProfileEditPhotoRemoved();
}

/// «حفظ», after the warning when the save un-verifies the business.
final class ProfileEditSubmitted extends ProfileEditEvent {
  const ProfileEditSubmitted();
}
