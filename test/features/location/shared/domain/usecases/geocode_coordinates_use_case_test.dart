import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';

import '../../../../../helpers/fake_place_search.dart';

class _FakeLocationRepository
    with FakePlaceSearch
    implements LocationRepository {
  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<LocationAddress>> saveAddress(LocationAddress address) async =>
      Success(address);

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
  test(
    'GeocodeCoordinatesUseCase calls repository geocodeCoordinates',
    () async {
      final repo = _FakeLocationRepository();
      final useCase = GeocodeCoordinatesUseCase(repo);

      final result = await useCase(
        const GeocodeCoordinatesParams(latitude: 24.7136, longitude: 46.6753),
      );

      expect(result, isA<Success<LocationAddress>>());
      final data = (result as Success<LocationAddress>).data;
      expect(data.city, 'الرياض');
      expect(data.district, 'النرجس');
      expect(data.latitude, 24.7136);
      expect(data.longitude, 46.6753);
    },
  );
}
