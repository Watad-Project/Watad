import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_city_suggestion_model.dart';

void main() {
  test('fromJson maps a suggestion of the geocode search', () {
    final suggestion = ProfileCitySuggestionModel.fromJson(const {
      'place_id': 'ChIJs4Zbxrm9vhURk3Jr2y3Bc-0',
      'title': ' العزيزية ',
      'subtitle': 'المدينة المنورة، السعودية',
    });

    expect(suggestion.placeId, 'ChIJs4Zbxrm9vhURk3Jr2y3Bc-0');
    expect(suggestion.title, 'العزيزية');
    expect(suggestion.subtitle, 'المدينة المنورة، السعودية');
  });

  test('a missing or empty subtitle is null', () {
    for (final subtitle in [null, '', '  ']) {
      final suggestion = ProfileCitySuggestionModel.fromJson({
        'place_id': 'ChIJs4Zbxrm9vhURk3Jr2y3Bc-0',
        'title': 'المدينة المنورة',
        'subtitle': subtitle,
      });

      expect(suggestion.subtitle, isNull);
    }
  });
}
