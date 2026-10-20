import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/router/routes/notifications_routes.dart';
import 'package:watad/core/utils/app_notification_links.dart';

/// Opens the screen of a notification's event (AppNotificationLinks,
/// ARCHITECTURE.md §13).
abstract final class NotificationNavigator {
  /// Opens the screen linked to [data]'s type. Returns false when nothing
  /// links it, or the route doesn't exist in this version of the app.
  static bool open(BuildContext context, Map<String, Object?> data) {
    final link = AppNotificationLinks.linkOf(data);
    if (link == null) return false;
    try {
      context.pushNamed(link.name, pathParameters: link.pathParameters);
      return true;
    } on Object {
      // The server can be newer than the app: stay where we are.
      return false;
    }
  }

  /// Opens the linked screen, or the notifications list when nothing links
  /// it: for a toast or a push, which have no list around them.
  static void openOrList(BuildContext context, Map<String, Object?> data) {
    if (!open(context, data)) {
      context.pushNamed(NotificationsRoutes.notificationsName);
    }
  }
}
