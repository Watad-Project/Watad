import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';

class NotificationTapModel extends NotificationTap {
  const NotificationTapModel({super.notificationId, super.data});

  /// Maps a tapped push's additional data: the notification's `data` plus
  /// `notification_id`, as send-push sends it (ARCHITECTURE.md §13).
  factory NotificationTapModel.fromJson(Map<String, dynamic> json) {
    final id = json['notification_id'];
    return NotificationTapModel(
      notificationId: id is String && id.isNotEmpty ? id : null,
      data: {
        for (final entry in json.entries)
          if (entry.key != 'notification_id') entry.key: entry.value,
      },
    );
  }
}
