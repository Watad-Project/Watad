import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A button to a management screen. Without [onTap] its screen isn't built
/// yet: it shows «قريباً» and opens nothing.
class AdminDashboardShortcut extends StatelessWidget {
  const AdminDashboardShortcut({
    required this.label,
    required this.icon,
    this.badge,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;

  /// Shown at the end instead of the arrow, e.g. how many are waiting.
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    final isReady = onTap != null;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isReady ? AppColors.ink : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isReady ? AppColors.ink : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (!isReady)
            AppStatusBadge(label: context.tr('dashboard.admin.coming_soon'))
          else ...[
            if (badge != null) AppStatusBadge(label: badge),
            // Points to the end of the line; it flips in RTL by itself.
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
