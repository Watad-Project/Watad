part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

/// Read the settings: when the screen opens, on retry, and back from the
/// bank details.
final class SettingsFetched extends SettingsEvent {
  const SettingsFetched();
}

/// A notification switch was tapped.
final class SettingsNotificationToggled extends SettingsEvent {
  const SettingsNotificationToggled(this.change);

  final SettingsNotificationChange change;
}

/// «تسجيل الخروج».
final class SettingsSignOutRequested extends SettingsEvent {
  const SettingsSignOutRequested();
}

/// «حذف الحساب», after the user confirmed.
final class SettingsAccountDeleteRequested extends SettingsEvent {
  const SettingsAccountDeleteRequested();
}
