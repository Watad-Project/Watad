import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';

/// The translation keys and tones of the support pages.
abstract final class SupportLabels {
  static String typeKey(ReportType type) => switch (type) {
    ReportType.fraud => 'support.type_fraud',
    ReportType.scam => 'support.type_scam',
    ReportType.harassment => 'support.type_harassment',
    ReportType.spam => 'support.type_spam',
    ReportType.inappropriateContent => 'support.type_inappropriate_content',
    ReportType.paymentIssue => 'support.type_payment_issue',
    ReportType.technicalIssue => 'support.type_technical_issue',
    ReportType.other => 'support.type_other',
  };

  static String statusKey(ReportStatus status) => switch (status) {
    ReportStatus.open => 'support.status_open',
    ReportStatus.inReview => 'support.status_in_review',
    ReportStatus.resolved => 'support.status_resolved',
    ReportStatus.dismissed => 'support.status_dismissed',
  };

  static AppTone statusTone(ReportStatus status) => switch (status) {
    ReportStatus.open || ReportStatus.inReview => AppTone.attention,
    ReportStatus.resolved => AppTone.success,
    ReportStatus.dismissed => AppTone.neutral,
  };

  /// «عن مستخدم», «عن منتج»…
  static String targetKey(SupportTargetKind kind) => switch (kind) {
    SupportTargetKind.user => 'support.about_user',
    SupportTargetKind.project => 'support.about_project',
    SupportTargetKind.item => 'support.about_item',
    SupportTargetKind.order => 'support.about_order',
    SupportTargetKind.review => 'support.about_review',
    SupportTargetKind.message => 'support.about_message',
  };
}
