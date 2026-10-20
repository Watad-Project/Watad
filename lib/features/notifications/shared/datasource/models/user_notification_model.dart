import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';

class UserNotificationModel extends UserNotification {
  const UserNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.createdAt,
    super.data,
    super.readAt,
  });

  /// Maps a `v_my_notifications` row as selected in
  /// NotificationsRemoteDataSourceImpl, or a new `notifications` row from
  /// Realtime (which has the same columns, and more).
  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    return UserNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: {if (json['data'] case final Map<String, dynamic> data) ...data},
      readAt: readAt == null ? null : DateTime.parse(readAt),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
