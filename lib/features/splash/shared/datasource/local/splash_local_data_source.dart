import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SplashLocalDataSource {
  Future<bool> isOnboardingSeen();

  Future<void> setOnboardingSeen();
}

class SplashLocalDataSourceImpl implements SplashLocalDataSource {
  const SplashLocalDataSourceImpl();

  static const String _onboardingSeenKey = 'onboarding_seen';

  @override
  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  @override
  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
