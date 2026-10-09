import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/localization/app_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a file named <group>.<language>.json belongs to its group', () {
    expect(AppTranslationsLoader.groupOf('auth.ar.json', 'ar'), 'auth');
    expect(
      AppTranslationsLoader.groupOf('business_verification.en.json', 'en'),
      'business_verification',
    );
  });

  test('other files and other languages are skipped', () {
    expect(AppTranslationsLoader.groupOf('auth.en.json', 'ar'), isNull);
    expect(AppTranslationsLoader.groupOf('ar.json', 'ar'), isNull);
    expect(AppTranslationsLoader.groupOf('Auth.ar.json', 'ar'), isNull);
    expect(AppTranslationsLoader.groupOf('auth/x.ar.json', 'ar'), isNull);
    expect(AppTranslationsLoader.groupOf('auth.ar.yaml', 'ar'), isNull);
  });

  // Reads the real asset bundle, so this also proves the files are bundled.
  test('loads every group of a language from the app assets', () async {
    final arabic = await const AppTranslationsLoader().load(
      AppLocalization.path,
      AppLocalization.arabic,
    );
    final english = await const AppTranslationsLoader().load(
      AppLocalization.path,
      AppLocalization.english,
    );

    expect(
      (arabic['common'] as Map<String, dynamic>)['retry'],
      'إعادة المحاولة',
    );
    expect((english['common'] as Map<String, dynamic>)['retry'], 'Try again');
  });
}
