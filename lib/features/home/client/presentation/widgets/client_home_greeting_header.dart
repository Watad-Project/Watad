import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

class ClientHomeGreetingHeader extends StatelessWidget {
  const ClientHomeGreetingHeader({
    required this.profile,
    this.currentHour,
    super.key,
  });

  final ClientHomeProfile profile;

  /// Optional hour to override DateTime.now() in tests.
  final int? currentHour;

  @override
  Widget build(BuildContext context) {
    final hour = currentHour ?? DateTime.now().hour;
    final greetingKey = hour < 12
        ? 'home.client.greeting_morning'
        : 'home.client.greeting_evening';
    final greeting = context.tr(greetingKey);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.fullName,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (profile.isPhoneVerified)
          AppStatusBadge(
            label: context.tr('home.client.phone_verified'),
            tone: AppTone.neutral,
          ),
      ],
    );
  }
}
