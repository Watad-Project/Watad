import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';

/// What the account tabs «حسابي» and «منشأتي» show (GRA-59): the signed-in
/// user's profile and their rating.
class ProfileOverview {
  const ProfileOverview({required this.profile, required this.rating});

  final MyProfile profile;
  final ProfileRating rating;
}
