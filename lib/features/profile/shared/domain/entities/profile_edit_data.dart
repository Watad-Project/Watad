import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_identity.dart';

/// What the edit profile screen opens on (GRA-60): the profile, and the
/// identity when the user has one. Clients give it at sign-up; contractors
/// may have none.
class ProfileEditData {
  const ProfileEditData({required this.profile, this.identity});

  final MyProfile profile;
  final ProfileIdentity? identity;
}
