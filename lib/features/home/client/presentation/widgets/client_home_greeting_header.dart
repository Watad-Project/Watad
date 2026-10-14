import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(greetingKey.tr(), style: AppTextStyles.caption),
              if (profile?.isPhoneVerified ?? false) ...[
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(
                  label: 'home.verified_phone'.tr(),
                  tone: AppTone.neutral,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(displayName, style: AppTextStyles.h1),
        ],
      ),
    );
  }
}
