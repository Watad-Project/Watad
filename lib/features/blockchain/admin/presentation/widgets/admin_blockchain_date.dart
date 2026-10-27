import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';

/// «٢٧ أكتوبر ٢٠٢٦ ١١:٠٥ ص»: a sync time on the phone's clock, in the
/// app's language; [time] null reads «لا يوجد».
abstract final class AdminBlockchainDate {
  static String format(BuildContext context, DateTime? time) {
    if (time == null) return context.tr('blockchain.admin.none');
    final locale = context.isArabic
        ? AppLocalization.arabic.languageCode
        : AppLocalization.english.languageCode;
    return DateFormat.yMMMd(locale).add_jm().format(time.toLocal());
  }
}
