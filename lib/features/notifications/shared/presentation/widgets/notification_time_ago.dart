import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';

/// «منذ ساعتين»: how long ago a notification came, in the app's language.
abstract final class NotificationTimeAgo {
  static String format(BuildContext context, DateTime time, DateTime now) {
    final elapsed = now.difference(time);
    if (elapsed.inMinutes < 1) return context.tr('notifications.just_now');
    if (elapsed.inHours < 1) {
      return _plural(context, 'notifications.minutes_ago', elapsed.inMinutes);
    }
    if (elapsed.inDays < 1) {
      return _plural(context, 'notifications.hours_ago', elapsed.inHours);
    }
    return _plural(context, 'notifications.days_ago', elapsed.inDays);
  }

  /// The count in the app's digits: «منذ ٣ أيام».
  static String _plural(BuildContext context, String key, int count) =>
      context.plural(key, count, args: [context.formatNumber(count)]);
}
