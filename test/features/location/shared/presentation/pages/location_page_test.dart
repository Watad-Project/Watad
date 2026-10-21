import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_google_map.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/entities/location_suggestion.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_place_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/search_places_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';
import 'package:watad/features/location/shared/presentation/pages/location_page.dart';

import '../../../../../helpers/fake_place_search.dart';
import '../../../../../helpers/pump_component.dart';

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
      street: 'طريق الملك فهد',
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

  setUp(() => repo = _FakeLocationRepository());

  Widget buildPage() {
    return BlocProvider(
      create: (_) => LocationBloc(
        SaveAddressUseCase(repo),
        GeocodeCoordinatesUseCase(repo),
        SearchPlacesUseCase(repo),
        GetPlaceUseCase(repo),
        searchDelay: Duration.zero,
      ),
      child: const LocationPage(),
    );
  }

  Finder inSuggestions(String text) => find.descendant(
    of: find.byKey(const Key('location_search_suggestions')),
    matching: find.text(text),
  );

  testWidgets(
    'renders LocationPage with map, search input and disabled confirm button when empty',
    (tester) async {
      await pumpLocalizedApp(tester, buildPage());

      expect(find.byKey(const Key('location_search_input')), findsOneWidget);
      expect(find.byType(AppGoogleMap), findsOneWidget);
      expect(find.byKey(const Key('location_confirm_button')), findsOneWidget);

      final button = tester.widget<AppButton>(
        find.byKey(const Key('location_confirm_button')),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('entering city and district enables confirm button', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, buildPage());

    await tester.enterText(
      find.byKey(const Key('location_city_input')),
      'الرياض',
    );
    await tester.enterText(
      find.byKey(const Key('location_district_input')),
      'النرجس',
    );
    await tester.pump();

    final button = tester.widget<AppButton>(
      find.byKey(const Key('location_confirm_button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('typing a city or a street suggests places to pick', (
    tester,
  ) async {
    repo.searchResult = const Success([
      LocationSuggestion(
        placeId: 'place-aziziyah',
        title: 'العزيزية',
        subtitle: 'المدينة المنورة، السعودية',
      ),
      LocationSuggestion(placeId: 'place-aziziyah-st', title: 'شارع العزيزية'),
    ]);
    await pumpLocalizedApp(tester, buildPage());

    await tester.enterText(
      find.byKey(const Key('location_search_input')),
      'العزيزية',
    );
    await tester.pumpAndSettle();
    expect(repo.searched, [('العزيزية', 'ar')]);
    expect(inSuggestions('العزيزية'), findsOneWidget);
    expect(inSuggestions('المدينة المنورة، السعودية'), findsOneWidget);
    expect(inSuggestions('شارع العزيزية'), findsOneWidget);

    await tester.tap(inSuggestions('شارع العزيزية'));
    await tester.pumpAndSettle();
    // The place is looked up for the map, its name fills the field, and
    // the list closes.
    expect(repo.placesAsked, ['place-aziziyah-st']);
    expect(find.text('شارع العزيزية'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(inSuggestions('العزيزية'), findsNothing);
    // The district field is the pin's, not the typed text.
    final district = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('location_district_input')),
        matching: find.byType(TextField),
      ),
    );
    expect(district.controller?.text, isNot('شارع العزيزية'));
  });

  testWidgets('a name nothing matches says so', (tester) async {
    await pumpLocalizedApp(tester, buildPage());

    await tester.enterText(
      find.byKey(const Key('location_search_input')),
      'مكان غير موجود',
    );
    await tester.pumpAndSettle();

    expect(inSuggestions('لا يوجد مكان بهذا الاسم'), findsOneWidget);
  });

  testWidgets('the suggestions fit large, bold text', (tester) async {
    repo.searchResult = const Success([
      LocationSuggestion(
        placeId: 'place-1',
        title: 'طريق الأمير محمد بن عبدالعزيز الفرعي',
        subtitle: 'حي العزيزية، المدينة المنورة، المملكة العربية السعودية',
      ),
      LocationSuggestion(placeId: 'place-2', title: 'العزيزية'),
      LocationSuggestion(placeId: 'place-3', title: 'العزيزية الجنوبية'),
    ]);
    await pumpLocalizedApp(
      tester,
      buildPage(),
      textScale: largeTextScale,
      boldText: true,
    );

    await tester.enterText(
      find.byKey(const Key('location_search_input')),
      'العزيزية',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
