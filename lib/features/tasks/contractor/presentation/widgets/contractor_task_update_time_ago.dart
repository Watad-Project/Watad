import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_localization.dart';

/// Formats a task's `lastUpdateAt` timestamp into a localized relative string
/// for the task-choice radio list on Step 1 (GRA-41).
abstract final class ContractorTaskUpdateTimeAgo {
  static String formatLastUpdate(
    BuildContext context,
    DateTime? lastUpdateAt, {
    DateTime? now,
  }) {
    if (lastUpdateAt == null) {
      return context.tr('tasks.contractor.update_no_updates_yet');
    }

    final reference = (now ?? DateTime.now()).toUtc();
    final updated = lastUpdateAt.toUtc();
    final diff = reference.difference(updated);

    final String relative;
    if (diff.inHours < 1) {
      relative = context.tr('tasks.contractor.time_just_now');
    } else if (diff.inDays < 1) {
      final hours = diff.inHours;
      relative = context.plural(
        'tasks.contractor.time_hours_ago',
        hours,
        args: [context.formatNumber(hours)],
      );
    } else {
      final days = diff.inDays;
      relative = context.plural(
        'tasks.contractor.time_days_ago',
        days,
        args: [context.formatNumber(days)],
      );
    }

    return context.tr('tasks.contractor.update_last_updated', args: [relative]);
  }
}
