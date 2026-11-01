import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// One row of a menu or a settings list: an icon, a label with an optional
/// line under it, an optional [tag] such as «قريبًا» or «مطلوب», and a
/// chevron at the end when the row opens something (it points left in
/// Arabic).
///
/// - Without [onTap] the row only shows something: no chevron, no ripple.
/// - [isMuted] grays the row out, e.g. for a screen that isn't built yet.
///   It hides the chevron, but [onTap] still runs, e.g. to say why.
///
/// The label and the line under it wrap, so the row grows with large text;
/// the tag takes at most 40% of the row and is cut with an ellipsis.
class AppMenuRow extends StatelessWidget {
  const AppMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.tag,
    this.tagTone = AppTone.neutral,
    this.onTap,
    this.isMuted = false,
  });

  final IconData icon;
  final String label;

  /// A line under the label, e.g. why the row is unavailable.
  final String? subtitle;

  /// A short status at the end of the row, in an [AppStatusBadge].
  final String? tag;
  final AppTone tagTone;
  final VoidCallback? onTap;
  final bool isMuted;

  /// The widest the [tag] gets, as a share of the row.
  static const double _maxTagShare = 0.4;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final tag = this.tag;
    final onTap = this.onTap;
    final color = isMuted ? AppColors.textSecondary : AppColors.ink;
    final row = LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.controlHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(color: color),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _maxTagShare,
                  ),
                  child: AppStatusBadge(label: tag, tone: tagTone),
                ),
              ],
              if (onTap != null && !isMuted) ...[
                const SizedBox(width: AppSpacing.xxs),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
