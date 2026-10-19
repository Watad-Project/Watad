import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_reports_time_ago.dart';

/// One report: «النوع — الهدف», who sent it and when, who was reported, its
/// status, and the actions its status and target allow:
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
    required this.onAssign,
    required this.onRemoveListing,
    required this.onSuspendUser,
    required this.onClose,
    required this.onDismiss,
    super.key,
  });

  final AdminReport report;
  final DateTime now;

  /// An action on this report is being sent.
  final bool isBusy;
  final VoidCallback onAssign;
  final ValueChanged<String> onRemoveListing;
  final ValueChanged<String> onSuspendUser;
  final VoidCallback onClose;
  final VoidCallback onDismiss;

  static String _typeKey(ReportType type) => switch (type) {
    ReportType.fraud => 'reports.type_fraud',
    ReportType.scam => 'reports.type_scam',
    ReportType.harassment => 'reports.type_harassment',
    ReportType.spam => 'reports.type_spam',
    ReportType.inappropriateContent => 'reports.type_inappropriate_content',
    ReportType.paymentIssue => 'reports.type_payment_issue',
    ReportType.technicalIssue => 'reports.type_technical_issue',
    ReportType.other => 'reports.type_other',
  };

  static String _targetKey(AdminReportTarget target) => switch (target) {
    AdminReportTarget.user => 'reports.target_user',
    AdminReportTarget.project => 'reports.target_project',
    AdminReportTarget.marketplaceItem => 'reports.target_marketplace_item',
    AdminReportTarget.order => 'reports.target_order',
    AdminReportTarget.review => 'reports.target_review',
    AdminReportTarget.message => 'reports.target_message',
  };

  @override
  Widget build(BuildContext context) {
    final type = context.tr(_typeKey(report.type));
    final target = report.target;
    final title = target == null
        ? type
        : '$type — ${context.tr(_targetKey(target))}';
    final time = AdminReportsTimeAgo.format(context, report.createdAt, now);
    final reporter = report.reporterName;
    final reported = report.targetUserName;
    final isOpen = report.status == ReportStatus.open;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.label)),
              AppStatusBadge(
                label: context.tr(
                  isOpen ? 'reports.status_open' : 'reports.status_in_review',
                ),
                tone: isOpen ? AppTone.attention : AppTone.neutral,
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
          const SizedBox(height: AppSpacing.md),
          _actions(context),
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
