import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';

/// Formats Riyadh calendar dates (`date` columns) on the contractor's project
/// schedule screen (GRA-37).
abstract final class ContractorTaskDate {
  static const Duration _riyadhOffset = Duration(hours: 3);

  /// Formats a Riyadh calendar day (e.g. «١٠ يناير» in Arabic, «Jan 10» in
  /// English) without shifting time zones.
  static String day(BuildContext context, DateTime date) =>
      DateFormat.MMMd(_locale(context)).format(date);

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
