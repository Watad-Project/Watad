import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';

/// «حفظ» on the edit profile screen (GRA-60): the profile as it was
/// loaded, and the form: the checked text fields and what was picked.
class ProfileSaveRequest {
  const ProfileSaveRequest({
    required this.profile,
    required this.check,
    this.photo = const ProfilePhotoKept(),
    this.specializedField,
    this.city,
  });

  final MyProfile profile;
  final ProfileFormCheck check;
  final ProfilePhotoChange photo;

  /// The picked specialty's label; null keeps the saved one.
  final String? specializedField;

  /// The picked city; null keeps the saved one.
  final String? city;

  /// What saving sends.
  ProfileChanges get changes => ProfileChanges.between(
    profile: profile,
    check: check,
    photo: photo,
    specializedField: specializedField,
    city: city,
  );
}
