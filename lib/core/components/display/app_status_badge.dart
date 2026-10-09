import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// A small round status label: orange waits for an action, green is done,
/// red is rejected, gray is neutral.
///
/// The caller maps its status (project, offer, task, payment, order) to a
/// translated [label] and an [AppTone].
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppTone.neutral,
    this.onImage = false,
  });

  final String label;
  final AppTone tone;

  /// A white badge, for placing on a photo (project and market cards).
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: onImage ? AppColors.surface : tone.badgeBackground,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(color: tone.foreground),
      ),
    );
  }
}
