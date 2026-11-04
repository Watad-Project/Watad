part of 'support_reports_bloc.dart';

sealed class SupportReportsState {
  const SupportReportsState();
}

final class SupportReportsInitial extends SupportReportsState {
  const SupportReportsInitial();
}

final class SupportReportsLoadInProgress extends SupportReportsState {
  const SupportReportsLoadInProgress();
}

final class SupportReportsLoadSuccess extends SupportReportsState {
  const SupportReportsLoadSuccess(this.reports);

  /// Newest first.
  final List<SupportReport> reports;
}

final class SupportReportsLoadFailure extends SupportReportsState {
  const SupportReportsLoadFailure(this.failure);

  final Failure failure;
}
