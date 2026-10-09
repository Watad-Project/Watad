import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/app.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

import 'helpers/pump_component.dart';

void main() {
  testWidgets('the app starts on /splash, in Arabic, right to left', (
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

    expect(find.byType(SplashPage), findsOneWidget);
    final page = tester.element(find.byType(SplashPage));
    expect(page.locale, AppLocalization.arabic);
    expect(Directionality.of(page), TextDirection.rtl);
    expect(find.text('هذه الشاشة قيد البناء.'), findsOneWidget);
  });
}
