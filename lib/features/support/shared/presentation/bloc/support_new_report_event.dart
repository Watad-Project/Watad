part of 'support_new_report_bloc.dart';

sealed class SupportNewReportEvent {
  const SupportNewReportEvent();
}

/// «إرسال البلاغ».
final class SupportNewReportSubmitted extends SupportNewReportEvent {
  const SupportNewReportSubmitted(this.report);

  final SupportNewReport report;
}
