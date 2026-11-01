/// The routes of lib/features/settings/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class SettingsRoutes {
  static const String settingsName = 'settings';
  static const String settingsPath = '/settings';

  /// `page` is `about`, `terms` or `privacy`.
  static const String settingsInfoName = 'settings-info';
  static const String settingsInfoPath = '/settings/info/:page';
}
