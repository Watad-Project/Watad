/// Mirror of the Postgres enum `payment_method`, how a marketplace order is
/// paid (ARCHITECTURE.md §4).
enum PaymentMethod {
  mada('mada'),
  creditCard('credit_card'),
  applePay('apple_pay'),
  stcPay('stc_pay'),
  bankTransfer('bank_transfer');

  const PaymentMethod(this.value);

  final String value;

  static PaymentMethod fromJson(String value) =>
      values.firstWhere((method) => method.value == value);

  String toJson() => value;
}
