import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';

/// Times in a chat, on the phone's clock and in the app's language.
abstract final class ChatTime {
  static String _locale(BuildContext context) => context.isArabic
      ? AppLocalization.arabic.languageCode
      : AppLocalization.english.languageCode;

  /// «٣:٠٥ م» under a message.
  static String time(BuildContext context, DateTime at) =>
      DateFormat.jm(_locale(context)).format(at.toLocal());

  /// «اليوم», «أمس», or the date, above each day's messages.
  static String day(BuildContext context, DateTime at, DateTime now) {
    final local = at.toLocal();
    final today = _dateOnly(now.toLocal());
    final day = _dateOnly(local);
    if (day == today) return context.tr('chat.today');
    if (day == today.subtract(const Duration(days: 1))) {
      return context.tr('chat.yesterday');
    }
    return DateFormat.yMMMd(_locale(context)).format(local);
  }

  /// «آخر ظهور ٣:٠٥ م», with the date when it wasn't today.
  static String lastSeen(BuildContext context, DateTime at, DateTime now) {
    final local = at.toLocal();
    final sameDay = _dateOnly(local) == _dateOnly(now.toLocal());
    final when = sameDay
        ? time(context, at)
        : DateFormat.yMMMd(_locale(context)).add_jm().format(local);
    return context.tr('chat.last_seen', args: [when]);
  }

  /// The same calendar day on the phone's clock.
  static bool sameDay(DateTime a, DateTime b) =>
      _dateOnly(a.toLocal()) == _dateOnly(b.toLocal());

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
