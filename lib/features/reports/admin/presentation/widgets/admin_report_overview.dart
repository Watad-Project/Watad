import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_labels.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_reports_date.dart';

/// Everything about one ticket: its type and status, when it was sent and
/// closed, who sent it and who handles it, what the user wrote, and what it
/// is about with the copy saved when it was sent.
class AdminReportOverview extends StatelessWidget {
  const AdminReportOverview({required this.report, super.key});

  final AdminReport report;

  static const EdgeInsetsGeometry _sectionPadding = EdgeInsetsDirectional.only(
    top: AppSpacing.lg,
    bottom: AppSpacing.xs,
  );

  @override
  Widget build(BuildContext context) {
    final resolvedAt = report.resolvedAt;
    final reporter = report.reporterName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                AdminReportLabels.title(context, report),
                style: AppTextStyles.h2,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppStatusBadge(
              label: context.tr(AdminReportLabels.statusKey(report.status)),
              tone: AdminReportLabels.statusTone(report.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('reports.sent_at'),
              value: AdminReportsDate.format(context, report.createdAt),
            ),
            if (resolvedAt != null)
              AppKeyValueRow(
                label: context.tr('reports.closed_at'),
                value: AdminReportsDate.format(context, resolvedAt),
              ),
            if (reporter != null)
              AppKeyValueRow(
                label: context.tr('reports.reporter_label'),
                value: reporter,
              ),
            AppKeyValueRow(
              label: context.tr('reports.assignee_label'),
              value: AdminReportLabels.assignee(context, report),
            ),
          ],
        ),
        AppSectionHeader(
          title: context.tr('reports.description'),
          padding: _sectionPadding,
        ),
        Text(report.description, style: AppTextStyles.body),
        if (report.target case final target?) ...[
          AppSectionHeader(
            title: context.tr('reports.subject'),
            padding: _sectionPadding,
          ),
          AppKeyValueList(
            rows: [
              AppKeyValueRow(
                label: context.tr('reports.subject_type'),
                value: context.tr(AdminReportLabels.targetKey(target)),
              ),
              if (report.targetUserName case final name?)
                AppKeyValueRow(
                  label: context.tr('reports.subject_user'),
                  value: name,
                ),
              if (report.targetId case final id?)
                AppKeyValueRow(
                  label: context.tr('reports.subject_id'),
                  value: id,
                  isMonospace: true,
                  isCopyable: true,
                ),
            ],
          ),
        ],
        if (report.evidence case final evidence?) ...[
          AppSectionHeader(
            title: context.tr('reports.evidence'),
            padding: _sectionPadding,
          ),
          _Evidence(text: evidence),
        ],
      ],
    );
  }
}

/// The saved copy of the reported message or review, set apart like a
/// quote.
class _Evidence extends StatelessWidget {
  const _Evidence({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Text(text, style: AppTextStyles.body),
      ),
    );
  }
}
