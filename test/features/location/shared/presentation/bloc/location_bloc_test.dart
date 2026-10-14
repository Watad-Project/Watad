import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';

class _FakeLocationRepository implements LocationRepository {
  LocationAddress? savedAddress;

  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<void>> saveAddress(LocationAddress address) async {
    savedAddress = address;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAddress(String id) async => const Success(null);
}

void main() {
  late _FakeLocationRepository repo;
  late SaveAddressUseCase saveAddressUseCase;
  late LocationBloc bloc;

  setUp(() {
    repo = _FakeLocationRepository();
    saveAddressUseCase = SaveAddressUseCase(repo);
    bloc = LocationBloc(saveAddressUseCase);
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
      emits(
        isA<LocationState>()
            .having((s) => s.status, 'status', LocationStatus.success)
            .having((s) => s.confirmedAddress, 'confirmedAddress', isNotNull),
      ),
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
}
