part of 'location_bloc.dart';

/// Status of the location screen operations.
enum LocationStatus {
  /// Initial idle state.
  initial,

  /// In-progress operation.
  loading,

  /// Location confirmed and ready to return.
  success,

  /// Operation failed.
  failure,
}

/// State of [LocationBloc].
final class LocationState {
  /// Creates an instance of [LocationState].
  const LocationState({
    this.status = LocationStatus.initial,
    this.address = const LocationAddress(
      id: '',
      name: '',
      city: '',
      district: '',
      street: '',
      buildingNumber: '',
      postalCode: '',
      latitude: 24.8214,
      longitude: 46.6438,
      isSaved: true,
    ),
    this.searchQuery = '',
    this.suggestions = const [],
    this.isSearching = false,
    this.hasNoResults = false,
    this.searchFailure,
    this.place,
    this.showSaveToggle = true,
    this.shouldSave = true,
    this.confirmedAddress,
    this.errorMessage,
    this.failure,
  });

  /// Current lifecycle status.
  final LocationStatus status;

  /// Address being edited / resolved from map pin.
  final LocationAddress address;

  /// Text in the search field.
  final String searchQuery;

  /// The places matching [searchQuery], under the search field.
  final List<LocationSuggestion> suggestions;

  /// A search is on its way.
  final bool isSearching;

  /// The search found no place with that name.
  final bool hasNoResults;

  /// Why the search, or finding a picked place, failed.
  final Failure? searchFailure;

  /// The picked place, for the map to show; a new one moves the map again.
  final LocationPlace? place;

  /// Whether the save toggle should be displayed.
  final bool showSaveToggle;

  /// Whether saving address is enabled.
  final bool shouldSave;

  /// The resulting address once confirmed.
  final LocationAddress? confirmedAddress;

  /// Error message if an error occurred.
  final String? errorMessage;

  /// Failure object if an error occurred.
  final Failure? failure;

  /// Whether the address has enough minimum data to confirm.
  bool get canConfirm =>
      address.city.trim().isNotEmpty && address.district.trim().isNotEmpty;

  /// Copies this state with updated fields.
  LocationState copyWith({
    LocationStatus? status,
    LocationAddress? address,
    String? searchQuery,
    List<LocationSuggestion>? suggestions,
    bool? isSearching,
    bool? hasNoResults,
    Failure? Function()? searchFailure,
    LocationPlace? place,
    bool? showSaveToggle,
    bool? shouldSave,
    LocationAddress? confirmedAddress,
    String? errorMessage,
    Failure? failure,
  }) {
    return LocationState(
      status: status ?? this.status,
      address: address ?? this.address,
      searchQuery: searchQuery ?? this.searchQuery,
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
      hasNoResults: hasNoResults ?? this.hasNoResults,
      searchFailure: searchFailure == null
          ? this.searchFailure
          : searchFailure(),
      place: place ?? this.place,
      showSaveToggle: showSaveToggle ?? this.showSaveToggle,
      shouldSave: shouldSave ?? this.shouldSave,
      confirmedAddress: confirmedAddress ?? this.confirmedAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      failure: failure ?? this.failure,
    );
  }
}
