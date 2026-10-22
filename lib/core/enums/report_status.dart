/// Mirror of the Postgres enum `report_status` (ARCHITECTURE.md §4).
enum ReportStatus {
  open('open'),
  inReview('in_review'),
  resolved('resolved'),
  dismissed('dismissed');

  const ReportStatus(this.value);

  final String value;

  static ReportStatus fromJson(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.open,
    );
  }

  String toJson() => value;
}
