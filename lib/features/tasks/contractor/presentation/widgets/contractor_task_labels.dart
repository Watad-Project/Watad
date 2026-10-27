import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_timeline.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';

/// Maps a [ContractorProjectTask] to its [AppTimelineState] dot and its
/// [AppIconTag] presentation on the contractor's schedule screen (GRA-37).
abstract final class ContractorTaskLabels {
  /// - `approved` → `done` (green `✓`)
  /// - `done` or `accepted` → `current` (orange dot)
  /// - `proposed` or `rejected` → `upcoming` (empty circle)
  static AppTimelineState timelineState(TaskStatus status) => switch (status) {
    TaskStatus.approved => AppTimelineState.done,
    TaskStatus.done || TaskStatus.accepted => AppTimelineState.current,
    TaskStatus.proposed || TaskStatus.rejected => AppTimelineState.upcoming,
  };

  /// Returns the translation key, icon, and [AppTone] for [task]'s status tag.
  static ({String key, IconData icon, AppTone tone}) tagOf(
    ContractorProjectTask task,
  ) => switch (task.status) {
    TaskStatus.approved => switch (task.paymentStatus) {
      PaymentStatus.paid => (
        key: 'tasks.contractor.status_approved_paid',
        icon: Icons.check,
        tone: AppTone.success,
      ),
      PaymentStatus.processing => (
        key: 'tasks.contractor.status_approved_processing',
        icon: Icons.check,
        tone: AppTone.success,
      ),
      PaymentStatus.pending => (
        key: 'tasks.contractor.status_approved_pending',
        icon: Icons.check,
        tone: AppTone.success,
      ),
      _ => (
        key: 'tasks.contractor.status_approved',
        icon: Icons.check,
        tone: AppTone.success,
      ),
    },
    TaskStatus.done => (
      key: 'tasks.contractor.status_done',
      icon: Icons.priority_high,
      tone: AppTone.attention,
    ),
    TaskStatus.accepted => switch ((
      task.lastUpdateDecision,
      task.hasLatestUpdate,
    )) {
      (TaskUpdateDecision.rejected, _) => (
        key: 'tasks.contractor.status_update_rejected',
        icon: Icons.close,
        tone: AppTone.danger,
      ),
      (_, true) => (
        key: 'tasks.contractor.status_in_progress',
        icon: Icons.priority_high,
        tone: AppTone.attention,
      ),
      _ => (
        key: 'tasks.contractor.status_accepted',
        icon: Icons.timelapse_outlined,
        tone: AppTone.neutral,
      ),
    },
    TaskStatus.proposed => (
      key: 'tasks.contractor.status_proposed',
      icon: Icons.question_mark,
      tone: AppTone.neutral,
    ),
    TaskStatus.rejected => (
      key: 'tasks.contractor.status_rejected',
      icon: Icons.close,
      tone: AppTone.danger,
    ),
  };
}
