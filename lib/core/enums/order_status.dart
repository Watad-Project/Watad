/// Mirror of the Postgres enum `order_status` (ARCHITECTURE.md §4).
enum OrderStatus {
  pendingPayment('pending_payment'),
  paid('paid'),
  shipped('shipped'),
  delivered('delivered'),
  cancelled('cancelled'),
  refunded('refunded');

  const OrderStatus(this.value);

  final String value;

  static OrderStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
