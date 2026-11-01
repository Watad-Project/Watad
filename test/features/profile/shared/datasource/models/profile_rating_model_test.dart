import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_rating_model.dart';

void main() {
  test('fromJson maps the rating of a rated user', () {
    final rating = ProfileRatingModel.fromJson(const {
      'rating_avg': 4.67,
      'rating_count': 3,
    });

    expect(rating.average, 4.67);
    expect(rating.count, 3);
  });

  test('an average that comes as a whole number is still a double', () {
    final rating = ProfileRatingModel.fromJson(const {
      'rating_avg': 5,
      'rating_count': 1,
    });

    expect(rating.average, 5.0);
  });

  test('nobody rated them yet: no average, a count of 0', () {
    final rating = ProfileRatingModel.fromJson(const {
      'rating_avg': null,
      'rating_count': 0,
    });

    expect(rating.average, isNull);
    expect(rating.count, 0);
  });
}
