/// An admin's action on what a report is about (remove the listing, suspend
/// the user), with the reason the other person reads. The report is resolved
/// with the same reason.
class AdminReportDecision {
  const AdminReportDecision({
    required this.reportId,
    required this.subjectId,
    required this.reason,
  });

  final String reportId;

  /// The listing to remove or the user to suspend.
  final String subjectId;
  final String reason;
}
