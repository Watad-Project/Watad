import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/location/shared/datasource/models/location_place_model.dart';

void main() {
  test('fromJson maps a place with the area to show', () {
    final model = LocationPlaceModel.fromJson({
      'lat': 21.5433,
      'lng': 39.1728,
      'viewport': {'south': 21.2, 'west': 39.0, 'north': 21.9, 'east': 39.4},
    });

    expect(model.latitude, 21.5433);
    expect(model.longitude, 39.1728);
    expect(model.viewport?.south, 21.2);
    expect(model.viewport?.west, 39.0);
    expect(model.viewport?.north, 21.9);
    expect(model.viewport?.east, 39.4);
  });

  test('a place without an area, with whole-number coordinates', () {
    final model = LocationPlaceModel.fromJson({
      'lat': 24,
      'lng': 46,
      'viewport': null,
    });

    expect(model.latitude, 24.0);
    expect(model.viewport, isNull);
  });
}
