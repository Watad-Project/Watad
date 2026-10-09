import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// A tinted tag with a small square mark: ✓ verified or approved,
/// ! waiting for someone, ? proposed.
///
/// Trust marks use it with [AppTone.success] and [Icons.check], and put the
/// ledger hash in [detail]. The design sheet asks to keep trust marks calm
/// and small: no currency symbols and no wallet addresses.
class AppIconTag extends StatelessWidget {
  const AppIconTag({
    super.key,
    required this.label,
    required this.icon,
    this.tone = AppTone.success,
    this.detail,
  });

  final String label;
  final IconData icon;
  final AppTone tone;

  /// A value after the label, written left to right in mono, e.g. a hash.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: tone.accent,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.xs),
              ),
            ),
            child: Icon(icon, size: 13, color: AppColors.white),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 13,
                color: tone.foreground,
              ),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              detail!,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
