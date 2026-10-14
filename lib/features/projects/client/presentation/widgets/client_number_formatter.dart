import 'package:watad/core/utils/money.dart';

/// Formats numbers, counts, ratings and currency amounts for client project screens.
abstract final class ClientNumberFormatter {
  static String formatAmount(Money money, {required bool isArabic}) {
    final intAmount = money.halalas ~/ 100;
    final formatted = _formatWithThousands(intAmount);
    return isArabic ? formatDigits(formatted, isArabic: true) : formatted;
  }

  static String formatRating(double rating, {required bool isArabic}) {
    final str = rating.toStringAsFixed(1);
    return isArabic
        ? formatDigits(str.replaceAll('.', '\u066B'), isArabic: true)
        : str;
  }

  static String formatCount(int count, {required bool isArabic}) {
    return isArabic
        ? formatDigits(count.toString(), isArabic: true)
        : count.toString();
  }

  static String formatDigits(String input, {required bool isArabic}) {
    if (!isArabic) return input;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ','];
    const arabic = [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669',
      '\u066C',
    ];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  static String _formatWithThousands(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
