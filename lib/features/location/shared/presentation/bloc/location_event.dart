part of 'location_bloc.dart';

/// Base class for all events in [LocationBloc].
sealed class LocationEvent {
  const LocationEvent();
}

/// Initializes the map screen with optional initial address and configuration.
final class LocationStarted extends LocationEvent {
  const LocationStarted({this.initialAddress, this.showSaveToggle = true});

  final LocationAddress? initialAddress;
  final bool showSaveToggle;
}

/// The user typed in the search bar: a city, district or street.
final class LocationSearchQueryChanged extends LocationEvent {
  const LocationSearchQueryChanged(this.query, {this.language = 'ar'});

  final String query;

  /// The app's language, for the suggestions' names.
  final String language;
}

/// The user pressed the keyboard's search key.
final class LocationSearchSubmitted extends LocationEvent {
  const LocationSearchSubmitted();
}

/// The user picked a suggestion: the map moves there.
final class LocationSuggestionSelected extends LocationEvent {
  const LocationSuggestionSelected(this.suggestion);

  final LocationSuggestion suggestion;
}

/// The pin position or map center changed.
final class LocationCoordinatesChanged extends LocationEvent {
  const LocationCoordinatesChanged({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// The user tapped 'Current Location'.
final class LocationCurrentPositionRequested extends LocationEvent {
  const LocationCurrentPositionRequested({
    this.city = '',
    this.district = '',
    this.street = '',
    this.buildingNumber = '',
    this.postalCode = '',
    this.latitude = 24.8214,
    this.longitude = 46.6438,
  });

  final String city;
  final String district;
  final String street;
  final String buildingNumber;
  final String postalCode;
  final double latitude;
  final double longitude;
}

/// The user edited the City field.
final class LocationCityChanged extends LocationEvent {
  const LocationCityChanged(this.city);

  final String city;
}

/// The user edited the District field.
final class LocationDistrictChanged extends LocationEvent {
  const LocationDistrictChanged(this.district);

  final String district;
}

/// The user edited the Street field.
final class LocationStreetChanged extends LocationEvent {
  const LocationStreetChanged(this.street);

  final String street;
}

/// The user edited the Building Number field.
final class LocationBuildingNumberChanged extends LocationEvent {
  const LocationBuildingNumberChanged(this.buildingNumber);

  final String buildingNumber;
}

/// The user edited the Postal Code field.
final class LocationPostalCodeChanged extends LocationEvent {
  const LocationPostalCodeChanged(this.postalCode);

  final String postalCode;
}

/// The user edited the Address Name field.
final class LocationNameChanged extends LocationEvent {
  const LocationNameChanged(this.name);

  final String name;
}

/// The user toggled save address.
final class LocationSaveToggled extends LocationEvent {
  const LocationSaveToggled(this.shouldSave);

  final bool shouldSave;
}

/// The user confirmed the chosen location.
final class LocationConfirmed extends LocationEvent {
  const LocationConfirmed();
}
