import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «منذ ساعة»: how long ago a report was sent, in the app's language.
abstract final class AdminReportsTimeAgo {
  static String format(BuildContext context, DateTime time, DateTime now) {
    final elapsed = now.difference(time);
    if (elapsed.inMinutes < 1) return context.tr('reports.just_now');
    if (elapsed.inHours < 1) {
      return context.plural('reports.minutes_ago', elapsed.inMinutes);
    }
    if (elapsed.inDays < 1) {
      return context.plural('reports.hours_ago', elapsed.inHours);
    }
    return context.plural('reports.days_ago', elapsed.inDays);
  }
}
