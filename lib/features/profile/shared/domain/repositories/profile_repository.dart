import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_business_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_identity.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_market_item.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_place.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_review.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_reviews_query.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_write.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';

abstract interface class ProfileRepository {
  /// The signed-in user's profile, with their business if they have one.
  Future<Result<MyProfile>> getMyProfile();

  /// The rating of the user with [userId].
  Future<Result<ProfileRating>> getRating(String userId);

  /// The signed-in user's ID number and phone; null when they have none.
  Future<Result<ProfileIdentity?>> getMyIdentity();

  /// Uploads [photo] into the signed-in user's folder of the `avatars`
  /// bucket, under a new name, and returns its path.
  Future<Result<String>> uploadAvatar(ProfilePhoto photo);

  /// Deletes the photo at [path] from the `avatars` bucket.
  Future<Result<void>> deleteAvatar(String path);

  /// Writes [write] to the signed-in user's `users` row.
  Future<Result<void>> updateUser(ProfileUserWrite write);

  /// Writes [changes] to the signed-in user's `businesses` row.
  Future<Result<void>> updateBusiness(ProfileBusinessChanges changes);

  /// Places in Saudi Arabia matching [query], named in Arabic.
  Future<Result<List<ProfileCitySuggestion>>> searchCities(String query);

  /// Where the place [placeId] of a suggestion is.
  Future<Result<ProfilePlace>> getPlace(String placeId);

  /// The city at [place], named in Arabic; null when Google knows none.
  Future<Result<String?>> cityAt(ProfilePlace place);

  /// The public profile of the user with [userId] (GRA-58); a
  /// `NotFoundFailure` when there's no such user.
  Future<Result<PublicProfile>> getPublicProfile(String userId);

  /// The active items of the user with [userId] on the market, newest
  /// first.
  Future<Result<List<ProfileMarketItem>>> getMarketItems(String userId);

  /// A page of the reviews about a user, newest first.
  Future<Result<List<ProfileReview>>> getReviews(ProfileReviewsQuery query);
}
