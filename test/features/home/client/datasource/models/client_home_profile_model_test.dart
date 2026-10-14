import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';

void main() {
  group('ClientHomeProfileModel', () {
    test('parses full_name, avatar_path and isPhoneVerified correctly', () {
      final json = {
        'full_name': 'Ahmad Al-Harbi',
        'avatar_path': 'avatars/user-1.jpg',
        'is_phone_verified': true,
      };

      final model = ClientHomeProfileModel.fromJson(json);

      expect(model.fullName, 'Ahmad Al-Harbi');
      expect(model.avatarPath, 'avatars/user-1.jpg');
      expect(model.isPhoneVerified, isTrue);
    });

    test('defaults missing fields gracefully', () {
      final model = ClientHomeProfileModel.fromJson(const {});

      expect(model.fullName, '');
      expect(model.avatarPath, isNull);
      expect(model.isPhoneVerified, isFalse);
    });
  });
}
