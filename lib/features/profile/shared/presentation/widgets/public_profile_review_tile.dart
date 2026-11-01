import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_review.dart';

/// One review on the public profile (GRA-58): who wrote it, the stars,
/// the date, whether it's about a project or an order, and the comment.
class PublicProfileReviewTile extends StatelessWidget {
  const PublicProfileReviewTile({required this.review, super.key});

  final ProfileReview review;

  static const int _maxStars = 5;

  @override
  Widget build(BuildContext context) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    final name = review.reviewerName.isEmpty
        ? context.tr('profile.public.no_name')
        : review.reviewerName;
    final comment = review.comment;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                url: review.reviewerAvatarUrl,
                size: 40,
                semanticLabel: name,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.label),
                    Text(
                      DateFormat.yMMMd(locale)
                          .format(review.createdAt.toLocal()),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: AppStatusBadge(
                  label: context.tr(
                    review.isFromProject
                        ? 'profile.public.from_project'
                        : 'profile.public.from_order',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: context.tr(
              'profile.public.stars',
              args: [context.formatNumber(review.rating)],
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var star = 1; star <= _maxStars; star++)
                    Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: star <= review.rating
                          ? AppColors.primary
                          : AppColors.controlOff,
                    ),
                ],
              ),
            ),
          ),
          if (comment != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(comment, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}
