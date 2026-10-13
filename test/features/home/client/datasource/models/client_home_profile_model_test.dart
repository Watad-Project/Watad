import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';

void main() {
  test('fromJson maps a v_my_profile row with all fields', () {
    final model = ClientHomeProfileModel.fromJson(const {
      'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'full_name': 'Omar Al-Ghamdi',
      'avatar_path': 'avatars/omar.jpg',
      'is_phone_verified': true,
    });

    expect(model.id, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
    expect(model.fullName, 'Omar Al-Ghamdi');
    expect(model.avatarPath, 'avatars/omar.jpg');
    expect(model.isPhoneVerified, isTrue);
  });

  test('fromJson handles null avatar_path and default isPhoneVerified', () {
    final model = ClientHomeProfileModel.fromJson(const {
      'id': 'user-123',
      'full_name': 'Sarah Ahmad',
      'avatar_path': null,
    });

    expect(model.id, 'user-123');
    expect(model.fullName, 'Sarah Ahmad');
    expect(model.avatarPath, isNull);
    expect(model.isPhoneVerified, isFalse);
  });
}
