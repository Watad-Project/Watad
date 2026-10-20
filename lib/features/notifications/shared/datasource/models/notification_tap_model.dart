import 'package:watad/features/notifications/shared/datasource/models/notification_target_model.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';

class NotificationTapModel extends NotificationTap {
  const NotificationTapModel({super.notificationId, super.target});

  /// Maps a tapped push's additional data: the notification's `data` plus
  /// `notification_id`, as send-push sends it (ARCHITECTURE.md §13).
  factory NotificationTapModel.fromJson(Map<String, dynamic> json) {
    final id = json['notification_id'];
    return NotificationTapModel(
      notificationId: id is String && id.isNotEmpty ? id : null,
      target: NotificationTargetModel.routeOf(json),
    );
  }
}
