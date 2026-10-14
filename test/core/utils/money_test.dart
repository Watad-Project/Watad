import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';

void main() {
  test('creates Money from halalas and JSON num', () {
    const m1 = Money.halalas(320000);
    final m2 = Money.fromJson(3200.0);
    expect(m1.halalas, 320000);
    expect(m1.sar, 3200.0);
    expect(m2.halalas, 320000);
    expect(m1, equals(m2));
    expect(m1.toJson(), 3200.0);
  });

  test('addition, subtraction, zero, and string representation', () {
    const zero = Money.zero();
    expect(zero.halalas, 0);

    const m1 = Money.halalas(150050);
    const m2 = Money.halalas(50050);
    final sum = m1 + m2;
    final diff = m1 - m2;

    expect(sum.halalas, 200100);
    expect(diff.halalas, 100000);
    expect(m1.toString(), '1500.5 SAR');
  });
}
