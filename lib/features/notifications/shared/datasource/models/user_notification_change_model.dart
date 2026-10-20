import 'package:watad/features/notifications/shared/datasource/models/user_notification_model.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';

class UserNotificationChangeModel extends UserNotificationChange {
  const UserNotificationChangeModel({
    required super.notification,
    required super.isNew,
  });

  /// Maps a Realtime change as NotificationsRemoteDataSourceImpl passes it:
  /// `event` (`INSERT` for a new notification, `UPDATE` when one is read)
  /// and `record`, the `notifications` row as it is now.
  factory UserNotificationChangeModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationChangeModel(
      notification: UserNotificationModel.fromJson(
        json['record'] as Map<String, dynamic>,
      ),
      isNew: json['event'] == 'INSERT',
    );
  }
}
