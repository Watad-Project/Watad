/// The routes of lib/features/location/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class LocationRoutes {
  static const String locationName = 'location';
  static const String locationPath = '/location';

  /// «عناويني»: my saved addresses (from the account tab).
  static const String locationAddressesName = 'location-addresses';
  static const String locationAddressesPath = '/location/addresses';
}
