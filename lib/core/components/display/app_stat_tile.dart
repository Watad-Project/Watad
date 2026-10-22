import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One number at a glance: a label, the number in large type, and an
/// optional line under it (e.g. «١٢ موثّقة»). With [onTap] the tile opens
/// what it counts and shows an arrow.
///
/// Pass the number already written for the app's language
/// (`context.formatNumber(count)`).
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.isHighlighted = false,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  /// Draws the number in the brand color, for what needs attention (e.g.
  /// requests waiting for review).
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    final icon = this.icon;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: Text(label, style: AppTextStyles.caption)),
              if (onTap != null)
                // Points to the end of the line; it flips in RTL by itself.
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.h1.copyWith(
              color: isHighlighted ? AppColors.primary : AppColors.ink,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(caption, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
