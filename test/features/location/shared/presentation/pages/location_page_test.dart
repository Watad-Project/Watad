import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_google_map.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/geocode_coordinates_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';
import 'package:watad/features/location/shared/presentation/pages/location_page.dart';

import '../../../../../helpers/pump_component.dart';

class _FakeLocationRepository implements LocationRepository {
  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<LocationAddress>> saveAddress(LocationAddress address) async =>
      Success(address);

  @override
  Future<Result<void>> deleteAddress(String id) async => const Success(null);

  @override
  Future<Result<LocationAddress>> geocodeCoordinates({
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
      latitude: lat,
      longitude: lng,
    ),
  );
}

void main() {
  Widget buildPage() {
    final repo = _FakeLocationRepository();
    return BlocProvider(
      create: (_) => LocationBloc(
        SaveAddressUseCase(repo),
        GeocodeCoordinatesUseCase(repo),
      ),
      child: const LocationPage(),
    );
  }

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
}
