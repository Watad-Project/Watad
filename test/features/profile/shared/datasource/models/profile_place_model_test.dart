import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_place_model.dart';

void main() {
  test("fromJson maps the geocode place answer's point", () {
    final place = ProfilePlaceModel.fromJson(const {
      'lat': 24.4672,
      'lng': 39.6111,
      'viewport': {'south': 24.3, 'west': 39.4, 'north': 24.6, 'east': 39.8},
    });

    expect(place.latitude, 24.4672);
    expect(place.longitude, 39.6111);
  });

  test('whole-number coordinates are doubles, and no viewport is fine', () {
    final place = ProfilePlaceModel.fromJson(const {
      'lat': 24,
      'lng': 39,
      'viewport': null,
    });

    expect(place.latitude, 24.0);
    expect(place.longitude, 39.0);
  });
}
