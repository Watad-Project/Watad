import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingLocalDataSource {
  Future<void> setOnboardingSeen();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl();

  /// The splash screen reads this same key to skip the onboarding
  /// (lib/features/splash/shared/datasource/local/), so the two must match.
  static const String _onboardingSeenKey = 'onboarding_seen';

  @override
  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
