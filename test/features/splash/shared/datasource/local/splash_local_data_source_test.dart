import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watad/features/splash/shared/datasource/local/splash_local_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('isOnboardingSeen returns false initially', () async {
    const dataSource = SplashLocalDataSourceImpl();

    expect(await dataSource.isOnboardingSeen(), isFalse);
  });

  test('setOnboardingSeen updates value to true', () async {
    const dataSource = SplashLocalDataSourceImpl();

    await dataSource.setOnboardingSeen();

    expect(await dataSource.isOnboardingSeen(), isTrue);
  });
}
