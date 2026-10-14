import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/utils/money.dart';

void main() {
  group('Money', () {
    test('creates from halalas correctly', () {
      const money = Money.halalas(15050);
      expect(money.halalas, 15050);
      expect(money.sar, 150.50);
      expect(money.toJson(), 150.50);
    });

    test('creates from SAR correctly', () {
      final money = Money.fromSar(250.75);
      expect(money.halalas, 25075);
      expect(money.sar, 250.75);
      expect(money.toJson(), 250.75);
    });

    test('fromJson parses num correctly', () {
      final money = Money.fromJson(500);
      expect(money.halalas, 50000);
      expect(money.sar, 500.0);
      expect(money.toJson(), 500.0);
    });

    test('equality and hashCode work as expected', () {
      const money1 = Money.halalas(1000);
      final money2 = Money.fromSar(10.0);
      expect(money1, equals(money2));
      expect(money1.hashCode, equals(money2.hashCode));
    });

    test('toString formats two decimal places', () {
      const money = Money.halalas(12345);
      expect(money.toString(), '123.45');
    });
  });
}
