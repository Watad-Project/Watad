import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/supabase/app_session.dart';

void main() {
  group('AppRole.fromProfile reads a v_my_profile row', () {
    test('staff are admins, even with a business', () {
      expect(
        AppRole.fromProfile(const {'is_admin': true, 'is_business': true}),
        AppRole.admin,
      );
    });

    test('a user with a business is a contractor', () {
      expect(
        AppRole.fromProfile(const {'is_admin': false, 'is_business': true}),
        AppRole.contractor,
      );
    });

    test('everyone else is a client, also without a row', () {
      expect(
        AppRole.fromProfile(const {'is_admin': false, 'is_business': false}),
        AppRole.client,
      );
      expect(
        AppRole.fromProfile(const {'is_admin': null, 'is_business': null}),
        AppRole.client,
      );
      expect(AppRole.fromProfile(const {}), AppRole.client);
    });
  });
}
