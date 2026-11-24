part of 'location_addresses_bloc.dart';

sealed class LocationAddressesEvent {
  const LocationAddressesEvent();
}

/// Load my addresses: when the page opens, on retry, pull to refresh and
/// after adding one.
final class LocationAddressesFetched extends LocationAddressesEvent {
  const LocationAddressesFetched();
}

/// «حذف», after the confirmation.
final class LocationAddressDeleted extends LocationAddressesEvent {
  const LocationAddressDeleted(this.address);

  final LocationAddress address;
}
