import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';

class _FakeLocationRepository implements LocationRepository {
  LocationAddress? savedAddress;

  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<LocationAddress>> saveAddress(LocationAddress address) async {
    savedAddress = address;
    return Success(address);
  }

  @override
  Future<Result<void>> deleteAddress(String id) async => const Success(null);

  @override
  Future<Result<LocationAddress>> addressAt({
    required double lat,
    required double lng,
  }) async => Success(
    LocationAddress(
      id: '',
      name: '',
      city: 'الرياض',
      district: 'النرجس',
      street: 'طريق عثمان بن عفان',
      buildingNumber: '1234',
      postalCode: '13324',
      additionalNumber: '3929',
      shortAddress: 'RAYB6780',
      latitude: lat,
      longitude: lng,
    ),
  );

  @override
  Future<Result<LocationAddress>> geocodeCoordinates({
    required double lat,
    required double lng,
  }) => addressAt(lat: lat, lng: lng);
}

void main() {
  late _FakeLocationRepository repo;
  late SaveAddressUseCase saveAddressUseCase;
  late GeocodeCoordinatesUseCase geocodeCoordinatesUseCase;
  late LocationBloc bloc;

  setUp(() {
    repo = _FakeLocationRepository();
    saveAddressUseCase = SaveAddressUseCase(repo);
    geocodeCoordinatesUseCase = GeocodeCoordinatesUseCase(repo);
    bloc = LocationBloc(saveAddressUseCase, geocodeCoordinatesUseCase);
  });

  tearDown(() => bloc.close());

  test('initial state has default coordinates and empty fields', () {
    expect(bloc.state.status, LocationStatus.initial);
    expect(bloc.state.address.latitude, 24.8214);
    expect(bloc.state.address.longitude, 46.6438);
    expect(bloc.state.canConfirm, isFalse);
  });

  test('LocationStarted with initialAddress updates state', () async {
    const initial = LocationAddress(
      id: 'addr_1',
      name: 'Home',
      city: 'Riyadh',
      district: 'Al Malqa',
      street: 'King Fahd Road',
      buildingNumber: '100',
      postalCode: '12345',
      latitude: 24.8,
      longitude: 46.6,
      isSaved: true,
    );

    bloc.add(const LocationStarted(initialAddress: initial));
    await expectLater(
      bloc.stream,
      emits(
        isA<LocationState>()
            .having((s) => s.address.name, 'name', 'Home')
            .having((s) => s.address.city, 'city', 'Riyadh')
            .having((s) => s.canConfirm, 'canConfirm', isTrue),
      ),
    );
  });

  test(
    'editing city and district updates state and enables confirmation',
    () async {
      bloc.add(const LocationCityChanged('Riyadh'));
      await expectLater(
        bloc.stream,
        emits(
          isA<LocationState>().having((s) => s.address.city, 'city', 'Riyadh'),
        ),
      );

      bloc.add(const LocationDistrictChanged('Al Nakheel'));
      await expectLater(
        bloc.stream,
        emits(
          isA<LocationState>()
              .having((s) => s.address.district, 'district', 'Al Nakheel')
              .having((s) => s.canConfirm, 'canConfirm', isTrue),
        ),
      );
    },
  );

  test('LocationConfirmed saves address and emits success', () async {
    bloc.add(const LocationCityChanged('Riyadh'));
    bloc.add(const LocationDistrictChanged('Al Nakheel'));
    bloc.add(const LocationSaveToggled(true));
    await pumpEventQueue();

    bloc.add(const LocationConfirmed());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<LocationState>().having(
          (s) => s.status,
          'status',
          LocationStatus.loading,
        ),
        isA<LocationState>()
            .having((s) => s.status, 'status', LocationStatus.success)
            .having((s) => s.confirmedAddress, 'confirmedAddress', isNotNull),
      ]),
    );

    expect(repo.savedAddress, isNotNull);
    expect(repo.savedAddress?.city, 'Riyadh');
    expect(repo.savedAddress?.district, 'Al Nakheel');
  });

  test('LocationConfirmed does nothing if canConfirm is false', () async {
    bloc.add(const LocationConfirmed());
    await pumpEventQueue();

    expect(bloc.state.status, LocationStatus.initial);
    expect(repo.savedAddress, isNull);
  });

  test('LocationCoordinatesChanged resolves geocoded address fields', () async {
    bloc.add(
      const LocationCoordinatesChanged(latitude: 24.7136, longitude: 46.6753),
    );

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<LocationState>()
            .having((s) => s.address.latitude, 'lat', 24.7136)
            .having((s) => s.address.longitude, 'lng', 46.6753),
        isA<LocationState>()
            .having((s) => s.address.city, 'city', 'الرياض')
            .having((s) => s.address.district, 'district', 'النرجس')
            .having((s) => s.address.street, 'street', 'طريق عثمان بن عفان')
            .having((s) => s.address.buildingNumber, 'bldg', '1234')
            .having((s) => s.address.postalCode, 'postal', '13324'),
      ]),
    );
  });

  test('LocationConfirmed emits failure when saveAddress fails', () async {
    final failingRepo = _FailingLocationRepository();
    final failingBloc = LocationBloc(
      SaveAddressUseCase(failingRepo),
      GeocodeCoordinatesUseCase(failingRepo),
    );

    failingBloc.add(const LocationCityChanged('Riyadh'));
    failingBloc.add(const LocationDistrictChanged('Al Nakheel'));
    failingBloc.add(const LocationSaveToggled(true));
    await pumpEventQueue();

    failingBloc.add(const LocationConfirmed());
    await expectLater(
      failingBloc.stream,
      emitsInOrder([
        isA<LocationState>().having(
          (s) => s.status,
          'status',
          LocationStatus.loading,
        ),
        isA<LocationState>()
            .having((s) => s.status, 'status', LocationStatus.failure)
            .having((s) => s.failure, 'failure', isNotNull),
      ]),
    );

    await failingBloc.close();
  });

  test(
    'LocationCoordinatesChanged preserves user edits typed before geocoding responds',
    () async {
      final delayedRepo = _DelayedLocationRepository();
      final delayedBloc = LocationBloc(
        SaveAddressUseCase(delayedRepo),
        GeocodeCoordinatesUseCase(delayedRepo),
      );

      delayedBloc.add(
        const LocationCoordinatesChanged(latitude: 24.7136, longitude: 46.6753),
      );
      await pumpEventQueue();

      // User starts typing before the response returns
      delayedBloc.add(const LocationStreetChanged('شارع الملك عبدالعزيز'));
      await pumpEventQueue();

      // Server responds with geocode result
      delayedRepo.completer.complete(
        const Success(
          LocationAddress(
            id: '',
            name: '',
            city: 'الرياض',
            district: 'النرجس',
            street: 'طريق عثمان بن عفان',
            buildingNumber: '1234',
            postalCode: '13324',
            additionalNumber: '3929',
            shortAddress: 'RAYB6780',
            latitude: 24.7136,
            longitude: 46.6753,
          ),
        ),
      );
      await pumpEventQueue();

      // Street typed by user was preserved, city/district/national address from server were applied
      expect(delayedBloc.state.address.street, 'شارع الملك عبدالعزيز');
      expect(delayedBloc.state.address.city, 'الرياض');
      expect(delayedBloc.state.address.district, 'النرجس');
      expect(delayedBloc.state.address.buildingNumber, '1234');
      expect(delayedBloc.state.address.additionalNumber, '3929');
      expect(delayedBloc.state.address.shortAddress, 'RAYB6780');

      await delayedBloc.close();
    },
  );

  test(
    'LocationCoordinatesChanged emits failure if geocoding fails but leaves fields editable',
    () async {
      final failingRepo = _FailingLocationRepository();
      final failingBloc = LocationBloc(
        SaveAddressUseCase(failingRepo),
        GeocodeCoordinatesUseCase(failingRepo),
      );

      failingBloc.add(
        const LocationCoordinatesChanged(latitude: 24.7136, longitude: 46.6753),
      );
      await pumpEventQueue();

      expect(failingBloc.state.status, LocationStatus.failure);
      expect(failingBloc.state.errorMessage, isNotNull);

      // User can still edit fields freely
      failingBloc.add(const LocationCityChanged('المدينة المنورة'));
      await pumpEventQueue();
      expect(failingBloc.state.address.city, 'المدينة المنورة');
      expect(failingBloc.state.status, LocationStatus.initial);

      await failingBloc.close();
    },
  );
}

class _DelayedLocationRepository extends _FakeLocationRepository {
  final completer = Completer<Result<LocationAddress>>();

  @override
  Future<Result<LocationAddress>> addressAt({
    required double lat,
    required double lng,
  }) => completer.future;
}

class _FailingLocationRepository implements LocationRepository {
  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<LocationAddress>> saveAddress(LocationAddress address) async =>
      const Failed(PermissionFailure('unauthorized'));

  @override
  Future<Result<void>> deleteAddress(String id) async => const Success(null);

  @override
  Future<Result<LocationAddress>> addressAt({
    required double lat,
    required double lng,
  }) async => const Failed(PermissionFailure('unauthorized'));

  @override
  Future<Result<LocationAddress>> geocodeCoordinates({
    required double lat,
    required double lng,
  }) async => const Failed(PermissionFailure('unauthorized'));
}
