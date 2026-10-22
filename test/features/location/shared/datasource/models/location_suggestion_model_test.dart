import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/location/shared/datasource/models/location_suggestion_model.dart';

void main() {
  test('fromJson maps a suggestion of the geocode search', () {
    final model = LocationSuggestionModel.fromJson({
      'place_id': 'ChIJ2YgYzXz5vxURa9o3d1t1gWk',
      'title': 'العزيزية',
      'subtitle': 'المدينة المنورة، السعودية',
    });

    expect(model.placeId, 'ChIJ2YgYzXz5vxURa9o3d1t1gWk');
    expect(model.title, 'العزيزية');
    expect(model.subtitle, 'المدينة المنورة، السعودية');
  });

  test('a suggestion without a subtitle', () {
    final model = LocationSuggestionModel.fromJson({
      'place_id': 'ChIJm3XoQHy7wRURk0QWd3J8Yzk',
      'title': 'جدة',
      'subtitle': null,
    });

    expect(model.subtitle, isNull);
  });
}
