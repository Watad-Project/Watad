import 'package:watad/core/enums/report_type.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';

/// A report to send: its type, the user's description, and what it's
/// about, if anything.
class SupportNewReport {
  const SupportNewReport({
    required this.type,
    required this.description,
    this.target,
  });

  final ReportType type;
  final String description;
  final SupportTarget? target;

  /// The description's length the database accepts, once trimmed.
  static const int minLength = 5;
  static const int maxLength = 5000;
}
