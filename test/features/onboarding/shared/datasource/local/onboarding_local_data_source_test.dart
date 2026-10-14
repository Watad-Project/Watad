import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watad/features/onboarding/shared/datasource/local/onboarding_local_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // The splash screen reads this exact key and value to skip the onboarding
  // (SplashLocalDataSourceImpl). If this test fails, both must change.
  test('setOnboardingSeen stores onboarding_seen = true', () async {
    await const OnboardingLocalDataSourceImpl().setOnboardingSeen();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'onboarding_seen'});
    expect(prefs.getBool('onboarding_seen'), isTrue);
  });
}
