import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/presentation/widgets/client_payment_format.dart';

void main() {
  test('writes an IBAN in groups of four', () {
    expect(
      ClientPaymentFormat.iban('SA0380000000608010167519'),
      'SA03 8000 0000 6080 1016 7519',
    );
  });

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
