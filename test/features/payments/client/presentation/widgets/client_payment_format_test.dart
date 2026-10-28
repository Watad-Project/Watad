import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_payment_format.dart';

void main() {
  test('writes an amount as a bank app takes it', () {
    expect(
      ClientPaymentFormat.plainAmount(const Money.halalas(3900000)),
      '39000',
    );
    expect(
      ClientPaymentFormat.plainAmount(const Money.halalas(3900050)),
      '39000.50',
    );
    expect(
      ClientPaymentFormat.plainAmount(const Money.halalas(3900005)),
      '39000.05',
    );
  });
}
