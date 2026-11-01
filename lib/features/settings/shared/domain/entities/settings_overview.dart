import 'package:watad/core/enums/notification_group.dart';

/// What the settings screen shows that comes from the server.
class SettingsOverview {
  const SettingsOverview({
    required this.isContractor,
    required this.hasBankDetails,
    required this.notifications,
  });

  /// A user with a business: they get «الحساب البنكي».
  final bool isContractor;

  /// The contractor saved where clients send bank transfers.
  final bool hasBankDetails;

  /// Whether each group's push and pop-up is on.
  final Map<NotificationGroup, bool> notifications;

  bool isOn(NotificationGroup group) => notifications[group] ?? true;

  SettingsOverview withNotification(NotificationGroup group, bool enabled) =>
      SettingsOverview(
        isContractor: isContractor,
        hasBankDetails: hasBankDetails,
        notifications: {...notifications, group: enabled},
      );
}
