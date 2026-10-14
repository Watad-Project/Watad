import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';

void main() {
  test('creates Money from halalas and json', () {
    const m1 = Money.halalas(1500050);
    expect(m1.halalas, 1500050);
    expect(m1.toJson(), 15000.5);
    expect(m1.toString(), '15000.50');

    final m2 = Money.fromJson(15000.5);
    expect(m2, m1);
  });

  test('equality, comparison and arithmetic work', () {
    const smaller = Money.halalas(100);
    const larger = Money.halalas(200);

    expect(smaller < larger, isTrue);
    expect(smaller <= larger, isTrue);
    expect(larger > smaller, isTrue);
    expect(larger >= smaller, isTrue);
    expect(smaller.compareTo(larger), -1);
    expect(larger.compareTo(smaller), 1);
    expect(smaller == const Money.halalas(100), isTrue);

    expect(smaller + larger, const Money.halalas(300));
    expect(larger - smaller, const Money.halalas(100));
  });
}
