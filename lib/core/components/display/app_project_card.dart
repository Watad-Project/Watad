import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// A project in a list: photo with its status, title, contractor, task
/// progress, dates and amount. Used in My projects, Contracts, the
/// dashboard and the project history, for clients and contractors alike.
///
/// Every text arrives ready to show: translated, and with numbers, dates and
/// amounts already formatted (amounts through `Money`).
class AppProjectCard extends StatelessWidget {
  const AppProjectCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.progress,
    required this.progressLabel,
    required this.percentLabel,
    required this.dateLabel,
    required this.amountLabel,
    this.statusTone = AppTone.success,
    this.imageUrl,
    this.onTap,
  });

  final String title;

  /// Usually the business name.
  final String subtitle;
  final String statusLabel;
  final AppTone statusTone;

  /// From 0 to 1.
  final double progress;

  /// E.g. "3 of 5 tasks".
  final String progressLabel;

  /// E.g. "60%".
  final String percentLabel;

  /// E.g. "January → August 2026".
  final String dateLabel;
  final String amountLabel;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: imageUrl),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  start: AppSpacing.sm,
                  child: AppStatusBadge(
                    label: statusLabel,
                    tone: statusTone,
                    onImage: true,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.pill),
                  ),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(progressLabel, style: AppTextStyles.caption),
                    ),
                    Text(percentLabel, style: AppTextStyles.caption),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(dateLabel, style: AppTextStyles.caption),
                    ),
                    Text(
                      amountLabel,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
