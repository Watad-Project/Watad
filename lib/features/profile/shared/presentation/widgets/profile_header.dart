import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';

/// The top of the account tab (GRA-59): the user's photo, name and rating,
/// «٤٫٨ (١٢)», or «لا تقييمات بعد» while nobody has rated them.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.profile, required this.rating, super.key});

  final MyProfile profile;
  final ProfileRating rating;

  /// The photo's diameter.
  static const double _avatarSize = 72;

  @override
  Widget build(BuildContext context) {
    final average = rating.average;
    final name = profile.fullName.trim();
    return Row(
      children: [
        AppAvatar(
          url: profile.avatarUrl,
          size: _avatarSize,
          semanticLabel: name.isEmpty ? null : name,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? context.tr('profile.no_name') : name,
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: average == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      average == null
                          ? context.tr('profile.no_ratings')
                          : context.tr(
                              'profile.rating',
                              args: [
                                context.formatNumber(average, decimals: 1),
                                context.formatNumber(rating.count),
                              ],
                            ),
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
