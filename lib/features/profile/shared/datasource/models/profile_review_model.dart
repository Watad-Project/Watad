import 'package:watad/features/profile/shared/domain/entities/profile_review.dart';

class ProfileReviewModel extends ProfileReview {
  const ProfileReviewModel({
    required super.id,
    required super.reviewerName,
    required super.rating,
    required super.isFromProject,
    required super.createdAt,
    super.reviewerAvatarUrl,
    super.comment,
  });

  /// Maps the `v_reviews` columns selected in ProfileRemoteDataSourceImpl,
  /// plus `reviewer_avatar_url` (the photo's public URL), which the data
  /// source adds.
  factory ProfileReviewModel.fromJson(Map<String, dynamic> json) {
    final comment = (json['comment'] as String?)?.trim();
    return ProfileReviewModel(
      id: json['id'] as String,
      reviewerName: (json['reviewer_name'] as String?)?.trim() ?? '',
      reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
      rating: (json['rating'] as num).toInt(),
      comment: comment == null || comment.isEmpty ? null : comment,
      isFromProject: json['context_type'] == 'project',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
