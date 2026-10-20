import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';
import 'package:watad/features/location/shared/datasource/models/location_place_model.dart';
import 'package:watad/features/location/shared/datasource/models/location_suggestion_model.dart';
import 'package:watad/features/location/shared/datasource/remote/location_remote_data_source.dart';
import 'package:watad/features/location/shared/datasource/repositories/location_repository_impl.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/entities/location_place.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';

class _FakeLocationRemoteDataSource implements LocationRemoteDataSource {
  final List<LocationAddressModel> addresses = [];
  bool shouldThrow = false;

  @override
  Future<List<LocationAddressModel>> getSavedAddresses() async {
    if (shouldThrow) throw Exception('Remote error');
    return addresses;
  }

  @override
  Future<LocationAddressModel> saveAddress(LocationAddressModel address) async {
    if (shouldThrow) throw Exception('Remote error');
    final saved = LocationAddressModel(
      id: address.id.isEmpty ? 'generated_uuid_1' : address.id,
      name: address.name,
      city: address.city,
      district: address.district,
      street: address.street,
      buildingNumber: address.buildingNumber,
      postalCode: address.postalCode,
      isSaved: true,
    );
    addresses.add(saved);
    return saved;
  }

  @override
  Future<void> deleteAddress(String id) async {
    if (shouldThrow) throw Exception('Remote error');
    addresses.removeWhere((a) => a.id == id);
  }

  @override
  Future<LocationAddressModel> addressAt({
    required double lat,
    required double lng,
  }) async {
    if (shouldThrow) throw Exception('Geocode error');
    return LocationAddressModel.fromGeocode(
      {
        'city': 'الرياض',
        'district': 'النرجس',
        'street': 'طريق عثمان بن عفان',
        'building_number': '1234',
        'postal_code': '13324',
        'additional_number': '5678',
        'short_address': 'RRRR1234',
        'formatted_address': 'الرياض · النرجس',
      },
      lat: lat,
      lng: lng,
    );
  }

  @override
  Future<Map<String, dynamic>> geocodeCoordinates({
    required double lat,
    required double lng,
  }) async {
    if (shouldThrow) throw Exception('Geocode error');
    return {
      'city': 'الرياض',
      'district': 'النرجس',
      'street': 'طريق عثمان بن عفان',
      'building_number': '1234',
      'postal_code': '13324',
      'additional_number': '5678',
      'short_address': 'RRRR1234',
      'formatted_address': 'الرياض · النرجس',
    };
  }

  /// The searches sent, as (query, language, near latitude).
  final List<(String, String, double?)> searched = [];

  @override
  Future<List<LocationSuggestionModel>> searchPlaces({
    required String query,
    required String language,
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    if (shouldThrow) throw Exception('Search error');
    searched.add((query, language, nearLatitude));
    return [
      LocationSuggestionModel.fromJson({
        'place_id': 'ChIJ2YgYzXz5vxURa9o3d1t1gWk',
        'title': 'العزيزية',
        'subtitle': 'المدينة المنورة، السعودية',
      }),
    ];
  }

  @override
  Future<LocationPlaceModel> getPlace(String placeId) async {
    if (shouldThrow) throw Exception('Place error');
    return LocationPlaceModel.fromJson({
      'lat': 24.4672,
      'lng': 39.6111,
      'viewport': null,
    });
  }
}

void main() {
  late _FakeLocationRemoteDataSource remote;
  late LocationRepositoryImpl repository;

  setUp(() {
    remote = _FakeLocationRemoteDataSource();
    repository = LocationRepositoryImpl(remote);
  });

  test('getSavedAddresses returns success with mapped entities', () async {
    remote.addresses.add(
      const LocationAddressModel(
        id: '1',
        name: 'Home',
        city: 'Riyadh',
        district: 'Al Malqa',
        street: 'Street 1',
        buildingNumber: '10',
        postalCode: '12345',
        isSaved: true,
      ),
    );

    final result = await repository.getSavedAddresses();

    expect(result, isA<Success<List<LocationAddress>>>());
    final list = (result as Success<List<LocationAddress>>).data;
    expect(list.length, 1);
    expect(list.first.name, 'Home');
  });

  test('saveAddress saves model and returns entity with id', () async {
    const entity = LocationAddress(
      id: '',
      name: 'Office',
      city: 'Jeddah',
      district: 'Al Rawdah',
      street: 'Street 2',
      buildingNumber: '20',
      postalCode: '54321',
      isSaved: true,
    );

    final result = await repository.saveAddress(entity);

    expect(result, isA<Success<LocationAddress>>());
    final saved = (result as Success<LocationAddress>).data;
    expect(saved.id, 'generated_uuid_1');
    expect(saved.name, 'Office');
    expect(remote.addresses.length, 1);
  });

  test('deleteAddress deletes address by id', () async {
    remote.addresses.add(
      const LocationAddressModel(
        id: 'to_delete',
        name: 'Old',
        city: 'Riyadh',
        district: 'Al Nakheel',
        street: 'Street',
        buildingNumber: '1',
        postalCode: '11111',
      ),
    );

    final result = await repository.deleteAddress('to_delete');

    expect(result, isA<Success<void>>());
    expect(remote.addresses.isEmpty, isTrue);
  });

  test(
    'geocodeCoordinates calls remote and returns mapped LocationAddress',
    () async {
      final result = await repository.geocodeCoordinates(
        lat: 24.7136,
        lng: 46.6753,
      );

      expect(result, isA<Success<LocationAddress>>());
      final addr = (result as Success<LocationAddress>).data;
      expect(addr.city, 'الرياض');
      expect(addr.district, 'النرجس');
      expect(addr.street, 'طريق عثمان بن عفان');
      expect(addr.buildingNumber, '1234');
      expect(addr.postalCode, '13324');
      expect(addr.latitude, 24.7136);
      expect(addr.longitude, 46.6753);
    },
  );

  test('searchPlaces returns the suggestions', () async {
    final result = await repository.searchPlaces(
      query: 'العزيزية',
      language: 'ar',
      nearLatitude: 24.47,
      nearLongitude: 39.61,
    );

    expect(result, isA<Success<List<LocationSuggestion>>>());
    final suggestions = (result as Success<List<LocationSuggestion>>).data;
    expect(suggestions.single.title, 'العزيزية');
    expect(remote.searched, [('العزيزية', 'ar', 24.47)]);
  });

  test('getPlace returns where the place is', () async {
    final result = await repository.getPlace('ChIJ2YgYzXz5vxURa9o3d1t1gWk');

    expect(result, isA<Success<LocationPlace>>());
    expect((result as Success<LocationPlace>).data.latitude, 24.4672);
  });

  test('a failed search is Failed', () async {
    remote.shouldThrow = true;

    final result = await repository.searchPlaces(query: 'جدة', language: 'ar');

    expect(result, isA<Failed<List<LocationSuggestion>>>());
  });

  test('guardSupabaseCall maps exceptions to Failed', () async {
    remote.shouldThrow = true;

    final result = await repository.getSavedAddresses();

    expect(result, isA<Failed<List<LocationAddress>>>());
  });
}
