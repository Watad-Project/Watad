import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/entities/location_place.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_place_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/search_places_use_case.dart';

part 'location_event.dart';
part 'location_state.dart';

/// Manages state for the shared location picker and map page.
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  /// Creates an instance of [LocationBloc].
  ///
  /// [searchDelay] is how long typing must pause before the search runs.
  LocationBloc(
    this._saveAddressUseCase,
    this._geocodeCoordinatesUseCase,
    this._searchPlaces,
    this._getPlace, {
    this.searchDelay = const Duration(milliseconds: 350),
  }) : super(const LocationState()) {
    on<LocationStarted>(_onStarted);
    on<LocationSearchQueryChanged>(_onSearchQueryChanged);
    on<LocationSearchSubmitted>(_onSearchSubmitted);
    on<LocationSuggestionSelected>(_onSuggestionSelected);
    on<LocationCoordinatesChanged>(_onCoordinatesChanged);
    on<LocationCurrentPositionRequested>(_onCurrentPositionRequested);
    on<LocationCityChanged>(_onCityChanged);
    on<LocationDistrictChanged>(_onDistrictChanged);
    on<LocationStreetChanged>(_onStreetChanged);
    on<LocationBuildingNumberChanged>(_onBuildingNumberChanged);
    on<LocationPostalCodeChanged>(_onPostalCodeChanged);
    on<LocationNameChanged>(_onNameChanged);
    on<LocationSaveToggled>(_onSaveToggled);
    on<LocationConfirmed>(_onConfirmed);
  }

  final SaveAddressUseCase _saveAddressUseCase;
  final GeocodeCoordinatesUseCase _geocodeCoordinatesUseCase;
  final SearchPlacesUseCase _searchPlaces;
  final GetPlaceUseCase _getPlace;

  /// One search per pause in typing, not one per letter.
  final Duration searchDelay;

  void _onStarted(LocationStarted event, Emitter<LocationState> emit) {
    if (event.initialAddress != null) {
      emit(
        state.copyWith(
          address: event.initialAddress,
          showSaveToggle: event.showSaveToggle,
          shouldSave: event.initialAddress!.isSaved,
        ),
      );
    } else {
      emit(state.copyWith(showSaveToggle: event.showSaveToggle));
    }
  }

  Future<void> _onSearchQueryChanged(
    LocationSearchQueryChanged event,
    Emitter<LocationState> emit,
  ) async {
    final searches =
        event.query.trim().length >= SearchPlacesUseCase.minQueryLength;
    // The last suggestions stay until the new ones arrive.
    emit(
      state.copyWith(
        searchQuery: event.query,
        suggestions: searches ? null : const [],
        isSearching: searches,
        hasNoResults: false,
        searchFailure: () => null,
      ),
    );
    if (!searches) return;

    await Future<void>.delayed(searchDelay);
    // A newer letter, or a picked suggestion, replaces this search.
    if (emit.isDone || state.searchQuery != event.query) return;
    final result = await _searchPlaces(
      SearchPlacesParams(
        query: event.query,
        language: event.language,
        nearLatitude: state.address.latitude,
        nearLongitude: state.address.longitude,
      ),
    );
    if (emit.isDone || state.searchQuery != event.query) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            suggestions: data,
            isSearching: false,
            hasNoResults: data.isEmpty,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            suggestions: const [],
            isSearching: false,
            searchFailure: () => failure,
          ),
        );
    }
  }

  /// The keyboard's search key picks the first suggestion.
  void _onSearchSubmitted(
    LocationSearchSubmitted event,
    Emitter<LocationState> emit,
  ) {
    final first = state.suggestions.firstOrNull;
    if (first != null) add(LocationSuggestionSelected(first));
  }

  /// Finds where the suggestion is; the map moves there, and its pin fills
  /// the address (LocationCoordinatesChanged).
  Future<void> _onSuggestionSelected(
    LocationSuggestionSelected event,
    Emitter<LocationState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: event.suggestion.title,
        suggestions: const [],
        isSearching: false,
        hasNoResults: false,
        searchFailure: () => null,
      ),
    );
    final result = await _getPlace(event.suggestion.placeId);
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(place: data));
      case Failed(:final failure):
        emit(state.copyWith(searchFailure: () => failure));
    }
  }

  Future<void> _onCoordinatesChanged(
    LocationCoordinatesChanged event,
    Emitter<LocationState> emit,
  ) async {
    final cityBefore = state.address.city;
    final districtBefore = state.address.district;
    final streetBefore = state.address.street;
    final buildingBefore = state.address.buildingNumber;
    final postalBefore = state.address.postalCode;

    emit(
      state.copyWith(
        status: LocationStatus.initial,
        errorMessage: null,
        address: state.address.copyWith(
          latitude: event.latitude,
          longitude: event.longitude,
        ),
      ),
    );

    final result = await _geocodeCoordinatesUseCase(
      GeocodeCoordinatesParams(
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    if (emit.isDone) return;

    if (result case Success(:final data)) {
      emit(
        state.copyWith(
          status: LocationStatus.initial,
          address: state.address.copyWith(
            latitude: event.latitude,
            longitude: event.longitude,
            city:
                state.address.city != cityBefore &&
                    state.address.city.isNotEmpty
                ? state.address.city
                : (data.city.isNotEmpty ? data.city : state.address.city),
            district:
                state.address.district != districtBefore &&
                    state.address.district.isNotEmpty
                ? state.address.district
                : (data.district.isNotEmpty
                      ? data.district
                      : state.address.district),
            street:
                state.address.street != streetBefore &&
                    state.address.street.isNotEmpty
                ? state.address.street
                : (data.street.isNotEmpty ? data.street : state.address.street),
            buildingNumber:
                state.address.buildingNumber != buildingBefore &&
                    state.address.buildingNumber.isNotEmpty
                ? state.address.buildingNumber
                : (data.buildingNumber.isNotEmpty
                      ? data.buildingNumber
                      : state.address.buildingNumber),
            postalCode:
                state.address.postalCode != postalBefore &&
                    state.address.postalCode.isNotEmpty
                ? state.address.postalCode
                : (data.postalCode.isNotEmpty
                      ? data.postalCode
                      : state.address.postalCode),
            additionalNumber: data.additionalNumber?.isNotEmpty == true
                ? data.additionalNumber
                : state.address.additionalNumber,
            shortAddress: data.shortAddress?.isNotEmpty == true
                ? data.shortAddress
                : state.address.shortAddress,
          ),
        ),
      );
    } else if (result case Failed(:final failure)) {
      emit(
        state.copyWith(
          status: LocationStatus.failure,
          failure: failure,
          errorMessage: failure.messageKey,
        ),
      );
    }
  }

  void _onCurrentPositionRequested(
    LocationCurrentPositionRequested event,
    Emitter<LocationState> emit,
  ) {
    emit(
      state.copyWith(
        address: state.address.copyWith(
          city: event.city.isNotEmpty ? event.city : state.address.city,
          district: event.district.isNotEmpty
              ? event.district
              : state.address.district,
          street: event.street.isNotEmpty ? event.street : state.address.street,
          buildingNumber: event.buildingNumber.isNotEmpty
              ? event.buildingNumber
              : state.address.buildingNumber,
          postalCode: event.postalCode.isNotEmpty
              ? event.postalCode
              : state.address.postalCode,
          latitude: event.latitude,
          longitude: event.longitude,
        ),
      ),
    );
  }

  void _onCityChanged(LocationCityChanged event, Emitter<LocationState> emit) {
    emit(
      state.copyWith(
        status: LocationStatus.initial,
        address: state.address.copyWith(city: event.city),
      ),
    );
  }

  void _onDistrictChanged(
    LocationDistrictChanged event,
    Emitter<LocationState> emit,
  ) {
    emit(
      state.copyWith(
        status: LocationStatus.initial,
        address: state.address.copyWith(district: event.district),
      ),
    );
  }

  void _onStreetChanged(
    LocationStreetChanged event,
    Emitter<LocationState> emit,
  ) {
    emit(
      state.copyWith(
        status: LocationStatus.initial,
        address: state.address.copyWith(street: event.street),
      ),
    );
  }

  void _onBuildingNumberChanged(
    LocationBuildingNumberChanged event,
    Emitter<LocationState> emit,
  ) {
    emit(
      state.copyWith(
        status: LocationStatus.initial,
        address: state.address.copyWith(buildingNumber: event.buildingNumber),
      ),
    );
  }

  void _onPostalCodeChanged(
    LocationPostalCodeChanged event,
    Emitter<LocationState> emit,
  ) {
    emit(
      state.copyWith(
        status: LocationStatus.initial,
        address: state.address.copyWith(postalCode: event.postalCode),
      ),
    );
  }

  void _onNameChanged(LocationNameChanged event, Emitter<LocationState> emit) {
    emit(
      state.copyWith(
        status: LocationStatus.initial,
        address: state.address.copyWith(name: event.name),
      ),
    );
  }

  void _onSaveToggled(LocationSaveToggled event, Emitter<LocationState> emit) {
    emit(state.copyWith(shouldSave: event.shouldSave));
  }

  Future<void> _onConfirmed(
    LocationConfirmed event,
    Emitter<LocationState> emit,
  ) async {
    if (!state.canConfirm) return;

    emit(state.copyWith(status: LocationStatus.loading));

    LocationAddress finalAddress = state.address.copyWith(
      isSaved: state.shouldSave,
    );

    if (state.shouldSave) {
      final saveResult = await _saveAddressUseCase(finalAddress);
      switch (saveResult) {
        case Success(:final data):
          finalAddress = data;
        case Failed(:final failure):
          emit(
            state.copyWith(
              status: LocationStatus.failure,
              failure: failure,
              errorMessage: failure.messageKey,
            ),
          );
          return;
      }
    }

    emit(
      state.copyWith(
        status: LocationStatus.success,
        confirmedAddress: finalAddress,
      ),
    );
  }
}
