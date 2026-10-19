import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

/// The client's photo (or the default avatar), «مساء الخير» and their name,
/// with «جوال موثّق» when their phone was confirmed.
class ClientHomeGreetingHeader extends StatelessWidget {
  const ClientHomeGreetingHeader({
    required this.profile,
    required this.now,
    super.key,
  });

  final ClientHomeProfile profile;

  /// The phone's local time, for the greeting.
  final DateTime now;

  static const double _avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final greeting = now.hour < 12
        ? 'home.greeting_morning'
        : 'home.greeting_evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          url: profile.avatarUrl,
          size: _avatarSize,
          semanticLabel: profile.fullName.isEmpty ? null : profile.fullName,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(greeting), style: AppTextStyles.caption),
              if (profile.fullName.isNotEmpty)
                Text(
                  profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h1,
                ),
            ],
          ),
        ),
        if (profile.isPhoneVerified)
          AppStatusBadge(
            label: context.tr('home.verified_phone'),
            tone: AppTone.neutral,
          ),
      ],
    );
  }
}
