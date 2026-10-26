import 'package:watad/core/components/display/app_timeline.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';

/// How a task reads on the client's screens (GRA-47): its status tags and
/// its dot on the timeline.
abstract final class ClientTaskLabels {
  /// The translation keys of [task]'s tags, with their tones: its status
  /// and, once it's approved, where its payment stands.
  static List<({String key, AppTone tone})> of(ClientProjectTask task) =>
      switch (task.status) {
        TaskStatus.approved => [
          (key: 'projects.client.task_status_approved', tone: AppTone.success),
          ...switch (task.paymentStatus) {
            PaymentStatus.paid => [
              (key: 'projects.client.task_status_paid', tone: AppTone.success),
            ],
            PaymentStatus.processing => [
              (
                key: 'projects.client.task_status_awaiting_contractor',
                tone: AppTone.attention,
              ),
            ],
            _ => const <({String key, AppTone tone})>[],
          },
        ],
        TaskStatus.done => [
          (key: 'projects.client.task_status_done', tone: AppTone.attention),
        ],
        TaskStatus.proposed => [
          (
            key: 'projects.client.task_status_proposed',
            tone: AppTone.attention,
          ),
        ],
        TaskStatus.accepted => [
          (key: 'projects.client.task_status_accepted', tone: AppTone.neutral),
        ],
        TaskStatus.rejected => [
          (key: 'projects.client.task_status_rejected', tone: AppTone.danger),
        ],
      };

  /// Approved tasks are done, the ones the contractor works on are current,
  /// and the rest (proposed or rejected) haven't started.
  static AppTimelineState timelineState(TaskStatus status) => switch (status) {
    TaskStatus.approved => AppTimelineState.done,
    TaskStatus.accepted || TaskStatus.done => AppTimelineState.current,
    TaskStatus.proposed || TaskStatus.rejected => AppTimelineState.upcoming,
  };
}
