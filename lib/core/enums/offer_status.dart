/// Mirror of the Postgres enum `offer_status` (ARCHITECTURE.md §4).
enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const OfferStatus(this.value);

  final String value;

  static OfferStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
