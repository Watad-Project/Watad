import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_part.dart';

/// What «حفظ» did (GRA-60): how each part went, and the profile as the
/// server has it afterwards.
class ProfileSaveOutcome {
  const ProfileSaveOutcome({
    required this.user,
    required this.business,
    this.profile,
  });

  final ProfileSavePart user;
  final ProfileSavePart business;

  /// Read back after saving; null when that read failed.
  final MyProfile? profile;

  /// No part failed.
  bool get isComplete =>
      user is! ProfileSavePartFailed && business is! ProfileSavePartFailed;

  /// At least one part was stored.
  bool get savedAnything =>
      user is ProfileSavePartSaved || business is ProfileSavePartSaved;
}
