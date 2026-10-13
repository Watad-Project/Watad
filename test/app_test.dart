import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/app.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

import 'helpers/fake_splash_repository.dart';
import 'helpers/pump_component.dart';

void main() {
  // The splash fake never answers, so the app stays on the splash page.
  setUp(() => registerFakeSplashBloc(FakeSplashRepository()));

  tearDown(getIt.reset);

  testWidgets('the app starts in Arabic, right to left on the splash page', (
    tester,
  ) async {
    // The same setup as main.dart, reading the translation files from disk.
    await tester.pumpWidget(
      AppLocalization.scope(
        assetLoader: const TestAssetLoader(),
        saveLocale: false,
        child: const WatadApp(),
      ),
    );
    await tester.pumpAndSettle();

    final page = tester.element(find.byType(Scaffold));
    expect(page.locale, AppLocalization.arabic);
    expect(Directionality.of(page), TextDirection.rtl);
    expect(find.byType(SplashPage), findsOneWidget);
  });
}
