import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';

/// «٢٢ أكتوبر ٢٠٢٦ ٤:٠٥ م»: a ticket's date and time, on the phone's clock,
/// in the app's language.
abstract final class AdminReportsDate {
  static String format(BuildContext context, DateTime time) {
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    return DateFormat.yMMMd(locale).add_jm().format(time.toLocal());
  }
}
