/// Mirror of the Postgres enum `payment_status` (ARCHITECTURE.md §4).
enum PaymentStatus {
  pending('pending'),
  processing('processing'),
  paid('paid'),
  failed('failed'),
  refunded('refunded'),
  cancelled('cancelled');

  const PaymentStatus(this.value);

  final String value;

  static PaymentStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
