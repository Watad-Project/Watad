import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';

/// Formats Riyadh calendar dates (`date` columns) and update timestamps on the
/// contractor's task screens (GRA-37, GRA-39).
abstract final class ContractorTaskDate {
  static const Duration _riyadhOffset = Duration(hours: 3);

  /// Formats a Riyadh calendar day (e.g. «١٠ يناير» in Arabic, «Jan 10» in
  /// English) without shifting time zones.
  static String day(BuildContext context, DateTime date) =>
      DateFormat.MMMd(_locale(context)).format(date);

  /// Formats when an update was sent on the phone's clock (e.g. «اليوم ٩:٤٠ ص»,
  /// «أمس ٩:٤٠ ص», or «٢٤ أكتوبر ٩:٤٠ ص»).
  static String sentAt(
    BuildContext context,
    DateTime createdAt, {
    DateTime? now,
  }) {
    final locale = _locale(context);
    final local = createdAt.toLocal();
    final ref = (now ?? DateTime.now()).toLocal();
    final localDay = DateTime(local.year, local.month, local.day);
    final refDay = DateTime(ref.year, ref.month, ref.day);
    final timeStr = DateFormat.jm(locale).format(local);
    if (localDay == refDay) {
      final todayWord = context.plural('tasks.contractor.time_days_ago', 0);
      return '$todayWord $timeStr';
    }
    if (localDay == refDay.subtract(const Duration(days: 1))) {
      final yesterdayWord = context.plural('tasks.contractor.time_days_ago', 1);
      return '$yesterdayWord $timeStr';
    }
    return DateFormat.MMMd(locale).add_jm().format(local);
  }

  /// Formats a [task]'s start and finish dates for its timeline subtitle:
  /// - Both start & finish: «بدأت ١٠ يناير · أُنجزت ١٨ يناير»
  /// - Finish only: «أُنجزت ٣ سبتمبر»
  /// - Start only (future or proposed): «تبدأ ١٥ أكتوبر»
  /// - Start only (today or past): «بدأت ١٠ يناير»
  /// - Neither: `null`
  static String? subtitle(
    BuildContext context,
    ContractorProjectTask task, {
    DateTime? today,
  }) {
    final start = task.startDate;
    final finish = task.finishDate;
    return switch ((start, finish)) {
      (final s?, final f?) => context.tr(
        'tasks.contractor.date_started_and_finished',
        args: [day(context, s), day(context, f)],
      ),
      (null, final f?) => context.tr(
        'tasks.contractor.date_finished',
        args: [day(context, f)],
      ),
      (final s?, null) => context.tr(
        _isUpcomingStart(task.status, s, today: today)
            ? 'tasks.contractor.date_starts'
            : 'tasks.contractor.date_started',
        args: [day(context, s)],
      ),
      (null, null) => null,
    };
  }

  static bool _isUpcomingStart(
    TaskStatus status,
    DateTime startDate, {
    DateTime? today,
  }) {
    if (status == TaskStatus.proposed) return true;
    final riyadhNow = (today ?? DateTime.now()).toUtc().add(_riyadhOffset);
    final riyadhToday = DateTime.utc(
      riyadhNow.year,
      riyadhNow.month,
      riyadhNow.day,
    );
    final startDay = DateTime.utc(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    return startDay.isAfter(riyadhToday);
  }

  static String _locale(BuildContext context) => context.isArabic
      ? AppLocalization.arabic.languageCode
      : AppLocalization.english.languageCode;
}
