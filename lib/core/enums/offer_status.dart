/// Mirror of the Postgres enum `offer_status` (ARCHITECTURE.md §4).
enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const OfferStatus(this.value);

  /// The exact value stored in Postgres.
  final String value;

  /// Throws on an unknown value: never guess a status.
  static OfferStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
