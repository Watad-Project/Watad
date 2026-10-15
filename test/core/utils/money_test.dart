import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';

void main() {
  test('fromJson converts decimals accurately to halalas', () {
    expect(Money.fromJson(10.50).halalas, 1050);
    expect(Money.fromJson(0.01).halalas, 1);
    expect(Money.fromJson(100).halalas, 10000);
  });

  test('toJson converts halalas to number in SAR', () {
    expect(const Money.halalas(1050).toJson(), 10.5);
    expect(const Money.halalas(10000).toJson(), 100);
  });

  test('arithmetic operators work correctly', () {
    const m1 = Money.halalas(2000);
    const m2 = Money.halalas(500);
    expect((m1 + m2).halalas, 2500);
    expect((m1 - m2).halalas, 1500);
  });

  test('comparison operators work correctly', () {
    const m1 = Money.halalas(1000);
    const m2 = Money.halalas(2000);
    expect(m1 < m2, isTrue);
    expect(m1 <= m2, isTrue);
    expect(m2 > m1, isTrue);
    expect(m2 >= m1, isTrue);
    expect(m1 == const Money.halalas(1000), isTrue);
  });

  test('toString formats with 2 decimal places', () {
    expect(const Money.halalas(1050).toString(), '10.50');
    expect(const Money.halalas(1000).toString(), '10.00');
  });
}
