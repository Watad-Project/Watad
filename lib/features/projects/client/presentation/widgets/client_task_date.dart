import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';

/// Dates on the client's task screens, in the app's language.
abstract final class ClientTaskDate {
  /// A Riyadh calendar day (a `date` column), e.g. «١٢ أكتوبر ٢٠٢٦»: shown
  /// as it is, never moved to the phone's time zone.
  static String day(BuildContext context, DateTime day) =>
      DateFormat.yMMMd(_locale(context)).format(day);

  /// A task's days: «١٢ أكتوبر ٢٠٢٦ – ٢٠ أكتوبر ٢٠٢٦» once it's done, «يبدأ
  /// ١٢ أكتوبر ٢٠٢٦» before, or that it has none yet.
  static String days(BuildContext context, DateTime? start, DateTime? finish) =>
      switch ((start, finish)) {
        (final start?, final finish?) => context.tr(
          'projects.client.task_dates',
          args: [day(context, start), day(context, finish)],
        ),
        (final start?, null) => context.tr(
          'projects.client.task_starts',
          args: [day(context, start)],
        ),
        _ => context.tr('projects.client.task_no_dates'),
      };

  static String _locale(BuildContext context) => context.isArabic
      ? AppLocalization.arabic.languageCode
      : AppLocalization.english.languageCode;
}
