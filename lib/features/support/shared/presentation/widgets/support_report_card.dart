import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';
import 'package:watad/features/support/shared/presentation/widgets/support_labels.dart';

/// One of my reports: its type and status, what it was about, the date,
/// my description, and the admin's answer once there is one.
class SupportReportCard extends StatelessWidget {
  const SupportReportCard({required this.report, super.key});

  final SupportReport report;

  @override
  Widget build(BuildContext context) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    final target = report.targetKind;
    final note = report.resolutionNote;
    final details = [
      DateFormat.yMMMd(locale).format(report.createdAt.toLocal()),
      if (target != null) context.tr(SupportLabels.targetKey(target)),
    ].join(context.tr('support.separator'));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.tr(SupportLabels.typeKey(report.type)),
                  style: AppTextStyles.label,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: AppStatusBadge(
                  label: context.tr(SupportLabels.statusKey(report.status)),
                  tone: SupportLabels.statusTone(report.status),
                ),
              ),
            ],
          ),
          Text(details, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body,
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('support.admin_answer'),
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(note, style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
