import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

class ClientHomeGreetingHeader extends StatelessWidget {
  const ClientHomeGreetingHeader({required this.profile, super.key});

  final ClientHomeProfile? profile;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greetingKey = hour < 12
        ? 'home.greeting_morning'
        : 'home.greeting_evening';
    final name = profile?.fullName.trim();
    final displayName = (name != null && name.isNotEmpty) ? name : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingKey.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  displayName,
                  style: AppTextStyles.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (profile?.isPhoneVerified ?? false)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: AppStatusBadge(
                label: 'home.verified_phone'.tr(),
                tone: AppTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}
