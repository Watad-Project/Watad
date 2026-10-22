import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';

/// How a ticket's type, target and status read, on its card and its
/// details page.
abstract final class AdminReportLabels {
  /// «احتيال — إعلان», or only the type when the ticket names no target.
  static String title(BuildContext context, AdminReport report) {
    final type = context.tr(typeKey(report.type));
    final target = report.target;
    return target == null ? type : '$type — ${context.tr(targetKey(target))}';
  }

  static String typeKey(ReportType type) => switch (type) {
    ReportType.fraud => 'reports.type_fraud',
    ReportType.scam => 'reports.type_scam',
    ReportType.harassment => 'reports.type_harassment',
    ReportType.spam => 'reports.type_spam',
    ReportType.inappropriateContent => 'reports.type_inappropriate_content',
    ReportType.paymentIssue => 'reports.type_payment_issue',
    ReportType.technicalIssue => 'reports.type_technical_issue',
    ReportType.other => 'reports.type_other',
  };

  static String targetKey(AdminReportTarget target) => switch (target) {
    AdminReportTarget.user => 'reports.target_user',
    AdminReportTarget.project => 'reports.target_project',
    AdminReportTarget.marketplaceItem => 'reports.target_marketplace_item',
    AdminReportTarget.order => 'reports.target_order',
    AdminReportTarget.review => 'reports.target_review',
    AdminReportTarget.message => 'reports.target_message',
  };

  static String statusKey(ReportStatus status) => switch (status) {
    ReportStatus.open => 'reports.status_open',
    ReportStatus.inReview => 'reports.status_in_review',
    ReportStatus.resolved => 'reports.status_resolved',
    ReportStatus.dismissed => 'reports.status_dismissed',
  };

  static AppTone statusTone(ReportStatus status) => switch (status) {
    ReportStatus.open => AppTone.attention,
    ReportStatus.inReview => AppTone.neutral,
    ReportStatus.resolved => AppTone.success,
    ReportStatus.dismissed => AppTone.danger,
  };

  /// «مسند إلى: …», or «غير مسند» while nobody took it.
  static String assignee(BuildContext context, AdminReport report) {
    final name = report.assignedAdminName;
    if (report.isAssignedToMe) return context.tr('reports.assigned_to_me');
    return name == null
        ? context.tr('reports.unassigned')
        : context.tr('reports.assigned_to', args: [name]);
  }
}
