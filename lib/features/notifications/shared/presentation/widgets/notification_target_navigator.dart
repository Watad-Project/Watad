import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';

/// Opens where a notification leads, by route name (ARCHITECTURE.md §13).
abstract final class NotificationTargetNavigator {
  static void open(BuildContext context, NotificationTarget target) {
    try {
      context.pushNamed(target.route, pathParameters: target.params);
    } on Object {
      // A route this version of the app doesn't have (the server can be
      // newer): stay where we are. The notification is still in the list.
    }
  }
}
