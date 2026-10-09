import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// Where a submission stands, in the color of its [tone]: pending (orange),
/// rejected with its reason and a retry action (red), or accepted (green).
/// Used for receipts, task updates, refunds and verification.
class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    super.key,
    required this.tone,
    required this.title,
    this.subtitle,
    this.reasonTitle,
    this.reasonText,
    this.action,
  });

  final AppTone tone;
  final String title;

  /// E.g. "Sent today 10:20".
  final String? subtitle;

  /// The rejection reason, shown in a white box under the title.
  final String? reasonTitle;
  final String? reasonText;

  /// Usually an `AppButton`, e.g. "Upload a new receipt".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hasReason = reasonTitle != null || reasonText != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.h2)),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tone.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textBody),
            ),
          if (hasReason) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
                border: Border.all(color: tone.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reasonTitle != null)
                    Text(
                      reasonTitle!,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 15,
                        color: tone.foreground,
                      ),
                    ),
                  if (reasonText != null)
                    Text(
                      reasonText!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            action!,
          ],
        ],
      ),
    );
  }
}
