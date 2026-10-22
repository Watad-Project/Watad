import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_place_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/search_places_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';
import 'package:watad/features/location/shared/presentation/pages/location_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_place_search.dart';
import '../../../../helpers/pump_router.dart';

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
  setUp(() {
    registerFakeAuthBloc(FakeAuthRepository());
    final repo = _FakeLocationRepository();
    getIt.registerFactory(
      () => LocationBloc(
        SaveAddressUseCase(repo),
        GeocodeCoordinatesUseCase(repo),
        SearchPlacesUseCase(repo),
        GetPlaceUseCase(repo),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets('every location route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: LocationRoutes.locationPath,
    );

    router.goNamed(LocationRoutes.locationName);
    await tester.pumpAndSettle();

    expect(currentPath(router), LocationRoutes.locationPath);
    expect(find.byType(LocationPage), findsOneWidget);
  });

  testWidgets('the save switch shows by default', (tester) async {
    await pumpAppRouter(tester, initialLocation: LocationRoutes.locationPath);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('location_save_switch')), findsOneWidget);
  });

  testWidgets('?save=required always saves: the save switch is hidden', (
    tester,
  ) async {
    await pumpAppRouter(
      tester,
      initialLocation: '${LocationRoutes.locationPath}?save=required',
    );
    await tester.pumpAndSettle();
    expect(find.byType(LocationPage), findsOneWidget);
    expect(find.byKey(const Key('location_save_switch')), findsNothing);
  });
}
