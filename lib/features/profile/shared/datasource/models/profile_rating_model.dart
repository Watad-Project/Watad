import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';

class ProfileRatingModel extends ProfileRating {
  const ProfileRatingModel({required super.count, super.average});

  /// Maps the `v_public_profiles` columns selected in
  /// ProfileRemoteDataSourceImpl. `rating_avg` is the average rounded to 2
  /// decimals, null until someone rates the user.
  factory ProfileRatingModel.fromJson(Map<String, dynamic> json) {
    final count = json['rating_count'] as int? ?? 0;
    final average = json['rating_avg'] as num?;
    return ProfileRatingModel(
      count: count,
      average: count == 0 ? null : average?.toDouble(),
    );
  }
}
