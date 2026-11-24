import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/delete_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_saved_addresses_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_addresses_bloc.dart';

import 'fake_place_search.dart';

/// Home, and the site of a project that is still going.
const List<LocationAddress> fakeSavedAddresses = [
  LocationAddress(
    id: 'a-home',
    name: 'المنزل',
    city: 'المدينة المنورة',
    district: 'العزيزية',
    street: 'شارع الملك عبدالله',
    buildingNumber: '2450',
    postalCode: '42311',
    isSaved: true,
  ),
  LocationAddress(
    id: 'a-site',
    name: 'موقع الفيلا',
    city: 'المدينة المنورة',
    district: 'الياسمين',
    street: 'طريق الهجرة',
    buildingNumber: '7421',
    postalCode: '42316',
    isSaved: true,
    isActiveProjectSite: true,
  ),
];

/// A hand-written [LocationRepository] for the saved addresses: it keeps
/// them, and a delete removes one, as the table does (APP_ARCHITECTURE.md
/// §16).
class FakeLocationRepository
    with FakePlaceSearch
    implements LocationRepository {
  List<LocationAddress> addresses = [...fakeSavedAddresses];
  Result<List<LocationAddress>>? addressesResult;
  Result<void>? deleteResult;

  /// The ids deleted, in order.
  final List<String> deleted = [];

  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() async =>
      addressesResult ?? Success(List.unmodifiable(addresses));

  @override
  Future<Result<LocationAddress>> saveAddress(LocationAddress address) async =>
      Success(address);

  @override
  Future<Result<void>> deleteAddress(String id) async {
    deleted.add(id);
    if (deleteResult case final result?) return result;
    addresses = [
      for (final address in addresses)
        if (address.id != id) address,
    ];
    return const Success(null);
  }

  @override
  Future<Result<LocationAddress>> addressAt({
    required double lat,
    required double lng,
  }) async => Success(fakeSavedAddresses.first);

  @override
  Future<Result<LocationAddress>> geocodeCoordinates({
    required double lat,
    required double lng,
  }) => addressAt(lat: lat, lng: lng);
}

/// For tests that open «عناويني»: its bloc over [repository]. Reset getIt
/// after the test.
void registerFakeLocationAddresses(FakeLocationRepository repository) {
  getIt.registerFactory(
    () => LocationAddressesBloc(
      GetSavedAddressesUseCase(repository),
      DeleteAddressUseCase(repository),
    ),
  );
}
