import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_labels.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_reports_time_ago.dart';

/// One ticket: «النوع — الهدف», who sent it and when, who was reported, its
/// status and who it is assigned to. A tap opens its details.
///
/// A ticket still to handle also has the quick actions its status and
/// target allow (a closed one has none):
///
/// - open: «إسناد لي»;
/// - a listing in review: «حذف الإعلان» and «إغلاق»;
/// - a user in review: «إيقاف المستخدم» and «رفض البلاغ»;
/// - anything else in review: «إغلاق» and «رفض البلاغ».
class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    required this.report,
    required this.now,
    required this.isBusy,
    required this.onTap,
    required this.onAssign,
    required this.onRemoveListing,
    required this.onSuspendUser,
    required this.onClose,
    required this.onDismiss,
    super.key,
  });

  final AdminReport report;
  final DateTime now;

  /// An action on this ticket is being sent.
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final ValueChanged<String> onRemoveListing;
  final ValueChanged<String> onSuspendUser;
  final VoidCallback onClose;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final time = AdminReportsTimeAgo.format(context, report.createdAt, now);
    final reporter = report.reporterName;
    final reported = report.targetUserName;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AdminReportLabels.title(context, report),
                  style: AppTextStyles.label,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(
                label: context.tr(AdminReportLabels.statusKey(report.status)),
                tone: AdminReportLabels.statusTone(report.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            reporter == null
                ? time
                : '${context.tr('reports.reporter', args: [reporter])} · $time',
            style: AppTextStyles.caption,
          ),
          if (reported != null)
            Text(
              context.tr('reports.reported_user', args: [reported]),
              style: AppTextStyles.caption,
            ),
          Text(
            AdminReportLabels.assignee(context, report),
            style: AppTextStyles.caption,
          ),
          if (!report.isClosed) ...[
            const SizedBox(height: AppSpacing.md),
            _actions(context),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final listingId = report.listingId;
    final userId = report.targetUserId;
    final (
      String main,
      VoidCallback onMain,
      String? other,
      VoidCallback? onOther,
    ) = switch (report.status) {
      ReportStatus.open => ('reports.assign', onAssign, null, null),
      _ when listingId != null => (
        'reports.remove_listing',
        () => onRemoveListing(listingId),
        'reports.close',
        onClose,
      ),
      _ when userId != null => (
        'reports.suspend_user',
        () => onSuspendUser(userId),
        'reports.dismiss',
        onDismiss,
      ),
      _ => ('reports.close', onClose, 'reports.dismiss', onDismiss),
    };
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: context.tr(main),
            variant: AppButtonVariant.dark,
            isLoading: isBusy,
            onPressed: isBusy ? null : onMain,
          ),
        ),
        if (other != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: context.tr(other),
              variant: AppButtonVariant.secondary,
              onPressed: isBusy ? null : onOther,
            ),
          ),
        ],
      ],
    );
  }
}
