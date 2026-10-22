/// Mirror of the Postgres enum `report_type` (ARCHITECTURE.md §4).
enum ReportType {
  fraud('fraud'),
  scam('scam'),
  harassment('harassment'),
  spam('spam'),
  inappropriateContent('inappropriate_content'),
  paymentIssue('payment_issue'),
  technicalIssue('technical_issue'),
  other('other');

  const ReportType(this.value);

  final String value;

  static ReportType fromJson(String value) {
    return ReportType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportType.other,
    );
  }

  String toJson() => value;
}
