import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_contractor_model.dart';

void main() {
  test('fromJson maps a v_contractors row', () {
    final model = ClientContractorModel.fromJson({
      'id': '0b8f3c1e-7d2a-4e51-9a63-5c4d2e1f0a98',
      'company_name': 'البناء المتين',
      'avatar_path': 'u-1/avatar.jpg',
      'avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-1/avatar.jpg',
      'city': ' المدينة المنورة ',
      'rating_avg': 4.8,
      'rating_count': 12,
      'completed_project_count': 64,
      'is_in_my_city': true,
    });

    expect(model.id, '0b8f3c1e-7d2a-4e51-9a63-5c4d2e1f0a98');
    expect(model.companyName, 'البناء المتين');
    expect(model.city, 'المدينة المنورة');
    expect(model.ratingAvg, 4.8);
    expect(model.ratingCount, 12);
    expect(model.completedProjectCount, 64);
    expect(model.isInMyCity, isTrue);
    expect(model.avatarUrl, endsWith('/avatars/u-1/avatar.jpg'));
  });

  test('a new contractor without a city, ratings, projects or photo', () {
    final model = ClientContractorModel.fromJson({
      'id': 'c-2',
      'company_name': 'إتقان للتشييد',
      'avatar_path': null,
      'avatar_url': null,
      'city': null,
      'rating_avg': null,
      'rating_count': 0,
      'completed_project_count': 0,
      'is_in_my_city': false,
    });

    expect(model.city, isNull);
    expect(model.ratingAvg, isNull);
    expect(model.completedProjectCount, 0);
    expect(model.isInMyCity, isFalse);
    expect(model.avatarUrl, isNull);
  });
}
