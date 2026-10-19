import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_suggested_contractor_model.dart';

void main() {
  test('fromJson maps a v_public_profiles row', () {
    final model = ClientSuggestedContractorModel.fromJson({
      'id': '0b8f3c1e-7d2a-4e51-9a63-5c4d2e1f0a98',
      'company_name': 'البناء المتين',
      'avatar_path': 'u-1/avatar.jpg',
      'avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-1/avatar.jpg',
      'rating_avg': 4.8,
      'rating_count': 64,
    });

    expect(model.id, '0b8f3c1e-7d2a-4e51-9a63-5c4d2e1f0a98');
    expect(model.companyName, 'البناء المتين');
    expect(model.ratingAvg, 4.8);
    expect(model.ratingCount, 64);
    expect(model.avatarUrl, endsWith('/avatars/u-1/avatar.jpg'));
  });

  test('a contractor without ratings or a photo', () {
    final model = ClientSuggestedContractorModel.fromJson({
      'id': 'c-2',
      'company_name': 'إتقان للتشييد',
      'avatar_path': null,
      'avatar_url': null,
      'rating_avg': null,
      'rating_count': 0,
    });

    expect(model.ratingAvg, isNull);
    expect(model.ratingCount, 0);
    expect(model.avatarUrl, isNull);
  });
}
