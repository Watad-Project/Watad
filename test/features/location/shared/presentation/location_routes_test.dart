import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_place_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/search_places_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';
import 'package:watad/features/location/shared/presentation/pages/location_addresses_page.dart';
import 'package:watad/features/location/shared/presentation/pages/location_page.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_location_repository.dart';
import '../../../../helpers/fake_place_search.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
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

  group('location-addresses', () {
    late FakeLocationRepository repository;

    setUp(() {
      // The router opens at the splash page first. Its fake never answers.
      registerFakeSplashBloc(FakeSplashRepository());
      repository = FakeLocationRepository();
      registerFakeLocationAddresses(repository);
    });

    Future<GoRouter> openAddresses(
      WidgetTester tester, {
      double textScale = 1,
      bool boldText = false,
    }) async {
      final router = await pumpAppRouter(
        tester,
        textScale: textScale,
        boldText: boldText,
      );
      router.goNamed(LocationRoutes.locationAddressesName);
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('lists my addresses at its path', (tester) async {
      final router = await openAddresses(tester);

      expect(currentPath(router), '/location/addresses');
      expect(find.byType(LocationAddressesPage), findsOneWidget);
      expect(find.text('المنزل'), findsOneWidget);
      expect(find.text('موقع الفيلا'), findsOneWidget);
      expect(
        find.text('موقع مشروع قائم، لا يمكن حذفه حتى ينتهي المشروع.'),
        findsOneWidget,
      );
    });

    testWidgets('a delete asks first, then removes the address', (
      tester,
    ) async {
      await openAddresses(tester);

      await tester.tap(find.text('حذف').first);
      await tester.pumpAndSettle();
      expect(find.text('حذف العنوان؟'), findsOneWidget);
      await tester.tap(find.text('حذف العنوان').last);
      await tester.pumpAndSettle();

      expect(repository.deleted, ['a-home']);
      expect(find.text('المنزل'), findsNothing);
      expect(find.text('تم حذف العنوان'), findsOneWidget);
    });

    testWidgets('no saved address says so', (tester) async {
      repository.addresses = [];
      await openAddresses(tester);

      expect(find.textContaining('لا عناوين محفوظة بعد'), findsOneWidget);
      expect(find.byKey(const Key('location_addresses_add')), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      repository.addressesResult = const Failed(NetworkFailure());
      await openAddresses(tester);

      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('fits large bold text', (tester) async {
      await openAddresses(tester, textScale: largeTextScale, boldText: true);

      expect(find.byType(LocationAddressesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
