import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';

abstract interface class ProfileRepository {
  /// The signed-in user's profile, with their business if they have one.
  Future<Result<MyProfile>> getMyProfile();

  /// The rating of the user with [userId].
  Future<Result<ProfileRating>> getRating(String userId);
}
