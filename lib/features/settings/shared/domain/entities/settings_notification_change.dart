import 'package:watad/core/enums/notification_group.dart';

/// One switch of «الإشعارات», as tapped.
class SettingsNotificationChange {
  const SettingsNotificationChange(this.group, {required this.enabled});

  final NotificationGroup group;
  final bool enabled;
}
