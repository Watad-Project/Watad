import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';

/// The type filter of the tickets list: all of them, the support requests
/// (technical, payment, other) or the moderation reports (fraud, scam,
/// harassment, spam, inappropriate content).
enum AdminReportsTypeFilter {
  all,
  support,
  moderation;

  bool matches(AdminReport report) => switch (this) {
    all => true,
    support => _isSupport(report.type),
    moderation => !_isSupport(report.type),
  };

  static bool _isSupport(ReportType type) => switch (type) {
    ReportType.technicalIssue ||
    ReportType.paymentIssue ||
    ReportType.other => true,
    ReportType.fraud ||
    ReportType.scam ||
    ReportType.harassment ||
    ReportType.spam ||
    ReportType.inappropriateContent => false,
  };
}
