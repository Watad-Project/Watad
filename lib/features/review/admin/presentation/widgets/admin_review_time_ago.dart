import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «منذ ساعتين»: how long ago a request was sent, in the app's language.
abstract final class AdminReviewTimeAgo {
  static String format(BuildContext context, DateTime time, DateTime now) {
    final elapsed = now.difference(time);
    if (elapsed.inMinutes < 1) return context.tr('review.just_now');
    if (elapsed.inHours < 1) {
      return context.plural('review.minutes_ago', elapsed.inMinutes);
    }
    if (elapsed.inDays < 1) {
      return context.plural('review.hours_ago', elapsed.inHours);
    }
    return context.plural('review.days_ago', elapsed.inDays);
  }
}
