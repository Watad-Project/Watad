part of 'support_new_report_bloc.dart';

enum SupportNewReportStatus { initial, sending, sent, failure }

final class SupportNewReportState {
  const SupportNewReportState({
    this.status = SupportNewReportStatus.initial,
    this.failure,
  });

  final SupportNewReportStatus status;

  /// Why the report wasn't sent.
  final Failure? failure;
}
