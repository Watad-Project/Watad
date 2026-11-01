import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_specialty_text.dart';

/// The top of the public profile (GRA-58): photo, name (with the verified
/// check for a verified business), specialty, rating, member since, and
/// online now or when last seen.
class PublicProfileHeader extends StatelessWidget {
  const PublicProfileHeader({
    required this.profile,
    required this.now,
    super.key,
  });

  final PublicProfile profile;

  /// To say «آخر ظهور» with a time today, or a date before.
  final DateTime now;

  static const double _avatarSize = 72;

  @override
  Widget build(BuildContext context) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    final secondary = AppTextStyles.body.copyWith(color: AppColors.textBody);
    final name = profile.isDeleted
        ? context.tr('profile.public.deleted')
        : profile.displayName.isEmpty
        ? context.tr('profile.public.no_name')
        : profile.displayName;
    final specialty = profile.isBusiness && !profile.isDeleted
        ? ProfileSpecialtyText.of(context, profile.specialty ?? '')
        : null;
    final average = profile.rating.average;
    final memberSince = profile.memberSince;
    final presence = _presence(context, locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppAvatar(
              url: profile.isDeleted ? null : profile.avatarUrl,
              size: _avatarSize,
              semanticLabel: name,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.isVerifiedBusiness && !profile.isDeleted)
                    AppVerifiedName(name: name, style: AppTextStyles.h2)
                  else
                    Text(name, style: AppTextStyles.h2),
                  if (specialty != null) Text(specialty, style: secondary),
                ],
              ),
            ),
          ],
        ),
        if (!profile.isDeleted) ...[
          const SizedBox(height: AppSpacing.md),
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
                          'profile.public.rating',
                          args: [
                            context.formatNumber(average, decimals: 1),
                            context.plural(
                              'profile.public.ratings',
                              profile.rating.count,
                              args: [
                                context.formatNumber(profile.rating.count),
                              ],
                            ),
                          ],
                        ),
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
          if (memberSince != null)
            Text(
              context.tr(
                'profile.public.member_since',
                args: [DateFormat.yMMMM(locale).format(memberSince.toLocal())],
              ),
              style: secondary,
            ),
          if (presence != null)
            Row(
              children: [
                if (profile.isOnline) ...[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(child: Text(presence, style: secondary)),
              ],
            ),
        ],
      ],
    );
  }

  /// «متصل الآن», «آخر ظهور ٣:٠٥ م» today, or with the date before.
  String? _presence(BuildContext context, String locale) {
    if (profile.isOnline) return context.tr('profile.public.online');
    final lastSeen = profile.lastSeenAt?.toLocal();
    if (lastSeen == null) return null;
    final today = now.toLocal();
    final sameDay =
        lastSeen.year == today.year &&
        lastSeen.month == today.month &&
        lastSeen.day == today.day;
    final when = sameDay
        ? DateFormat.jm(locale).format(lastSeen)
        : DateFormat.yMMMd(locale).add_jm().format(lastSeen);
    return context.tr('profile.public.last_seen', args: [when]);
  }
}
