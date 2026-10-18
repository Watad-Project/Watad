import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_network_image.dart';
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
    final avatarUrl = profile?.avatarPath;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.primaryBorder, width: 1.5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? AppNetworkImage(
                          url: avatarUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          semanticLabel: displayName,
                        )
                      : Center(
                          child: initial.isNotEmpty
                              ? Text(
                                  initial,
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
              ],
            ),
          ),
          if (profile?.isPhoneVerified ?? false)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
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
