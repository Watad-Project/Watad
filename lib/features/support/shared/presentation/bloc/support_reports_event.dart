part of 'support_reports_bloc.dart';

sealed class SupportReportsEvent {
  const SupportReportsEvent();
}

/// Load my reports: when the page opens, on retry, pull to refresh and
/// after sending a new one.
final class SupportReportsFetched extends SupportReportsEvent {
  const SupportReportsFetched();
}
