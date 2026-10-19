import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';

void main() {
  test('fromJson maps a realistic address map', () {
    final json = {
      'id': 'addr_123',
      'name': 'Home',
      'city': 'Riyadh',
      'district': 'An Narjis',
      'street': 'Prince Salman Road',
      'building_number': '7421',
      'postal_code': '13325',
      'latitude': 24.8214,
      'longitude': 46.6438,
      'is_saved': true,
    };

    final model = LocationAddressModel.fromJson(json);

    expect(model.id, 'addr_123');
    expect(model.name, 'Home');
    expect(model.city, 'Riyadh');
    expect(model.district, 'An Narjis');
    expect(model.street, 'Prince Salman Road');
    expect(model.buildingNumber, '7421');
    expect(model.postalCode, '13325');
    expect(model.latitude, 24.8214);
    expect(model.longitude, 46.6438);
    expect(model.isSaved, isTrue);
  });

  test('toJson serializes correctly', () {
    const model = LocationAddressModel(
      id: 'addr_123',
      name: 'Home',
      city: 'Riyadh',
      district: 'An Narjis',
      street: 'Prince Salman Road',
      buildingNumber: '7421',
      postalCode: '13325',
      latitude: 24.8214,
      longitude: 46.6438,
      isSaved: true,
    );

    final json = model.toJson();

    expect(json['id'], 'addr_123');
    expect(json['name'], 'Home');
    expect(json['city'], 'Riyadh');
    expect(json['district'], 'An Narjis');
    expect(json['street'], 'Prince Salman Road');
    expect(json['building_number'], '7421');
    expect(json['postal_code'], '13325');
    expect(json['latitude'], 24.8214);
    expect(json['longitude'], 46.6438);
    expect(json['is_saved'], isTrue);
  });

  test('fromEntity converts domain entity to model', () {
    const entity = LocationAddress(
      id: 'addr_entity',
      name: 'Office',
      city: 'Jeddah',
      district: 'Al Rawdah',
      street: 'Al Amir Sultan',
      buildingNumber: '1234',
      postalCode: '21577',
      latitude: 21.5433,
      longitude: 39.1728,
      isSaved: false,
    );

    final model = LocationAddressModel.fromEntity(entity);

    expect(model.id, entity.id);
    expect(model.name, entity.name);
    expect(model.city, entity.city);
    expect(model.district, entity.district);
    expect(model.street, entity.street);
    expect(model.buildingNumber, entity.buildingNumber);
    expect(model.postalCode, entity.postalCode);
    expect(model.latitude, entity.latitude);
    expect(model.longitude, entity.longitude);
    expect(model.isSaved, entity.isSaved);
    expect(model.toEntity(), equals(entity));
  });

  test('toSupabaseMap contains only the six §3a columns', () {
    const model = LocationAddressModel(
      id: 'addr_123',
      name: 'Villa',
      city: 'Riyadh',
      district: 'Al Malqa',
      street: 'King Salman',
      buildingNumber: '12',
      postalCode: '13521',
      latitude: 24.8,
      longitude: 46.6,
      isSaved: true,
    );

    final map = model.toSupabaseMap();

    expect(map, {
      'name': 'Villa',
      'city': 'Riyadh',
      'district': 'Al Malqa',
      'street': 'King Salman',
      'building_number': '12',
      'postal_code': '13521',
    });
    expect(map.keys.toSet(), {
      'name',
      'city',
      'district',
      'street',
      'building_number',
      'postal_code',
    });
  });

  test('fromGeocode parses Saudi national address fields and coords', () {
    final geocodeJson = {
      'city': 'الرياض',
      'district': 'النرجس',
      'street': 'رقم 116',
      'building_number': '6780',
      'postal_code': '13326',
      'additional_number': '3929',
      'short_address': 'RAYB6780',
    };

    final model = LocationAddressModel.fromGeocode(
      geocodeJson,
      lat: 24.8214,
      lng: 46.6438,
    );

    expect(model.city, 'الرياض');
    expect(model.district, 'النرجس');
    expect(model.street, 'رقم 116');
    expect(model.buildingNumber, '6780');
    expect(model.postalCode, '13326');
    expect(model.additionalNumber, '3929');
    expect(model.shortAddress, 'RAYB6780');
    expect(model.latitude, 24.8214);
    expect(model.longitude, 46.6438);

    // Verify toSupabaseMap does not include additional_number, short_address, or lat/lng
    final dbMap = model.toSupabaseMap();
    expect(dbMap.containsKey('additional_number'), isFalse);
    expect(dbMap.containsKey('short_address'), isFalse);
    expect(dbMap.containsKey('latitude'), isFalse);
    expect(dbMap.containsKey('longitude'), isFalse);
    expect(dbMap.length, 6);
  });
}
