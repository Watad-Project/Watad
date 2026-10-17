import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';
import 'package:watad/features/location/shared/datasource/remote/location_remote_data_source.dart';
import 'package:watad/features/location/shared/datasource/repositories/location_repository_impl.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';

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

  test('guardSupabaseCall maps exceptions to Failed', () async {
    remote.shouldThrow = true;

    final result = await repository.getSavedAddresses();

    expect(result, isA<Failed<List<LocationAddress>>>());
  });
}
