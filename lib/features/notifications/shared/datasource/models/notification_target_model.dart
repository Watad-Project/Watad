import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';

class NotificationTargetModel extends NotificationTarget {
  const NotificationTargetModel({required super.route, super.params});

  /// Maps a notification's `data` (the row's, or a push's additional
  /// data): `{"route": "<route name>", "params": {"id": "…"}}`. Call it only
  /// when `route` is a string; see [routeOf].
  factory NotificationTargetModel.fromJson(Map<String, dynamic> json) {
    final params = json['params'];
    return NotificationTargetModel(
      route: json['route'] as String,
      params: {
        if (params is Map)
          for (final entry in params.entries)
            if (entry.value != null) '${entry.key}': '${entry.value}',
      },
    );
  }

  /// The target of [data], or null when it leads nowhere.
  static NotificationTargetModel? routeOf(Object? data) =>
      data is Map<String, dynamic> && data['route'] is String
      ? NotificationTargetModel.fromJson(data)
      : null;
}
