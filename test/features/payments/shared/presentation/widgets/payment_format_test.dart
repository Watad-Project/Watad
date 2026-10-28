import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/payments/shared/presentation/widgets/payment_format.dart';

void main() {
  test('writes an IBAN in groups of four', () {
    expect(
      PaymentFormat.iban('SA0380000000608010167519'),
      'SA03 8000 0000 6080 1016 7519',
    );
  });
}
