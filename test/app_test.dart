import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/app.dart';
import 'package:watad/core/localization/app_localization.dart';

import 'helpers/pump_component.dart';

void main() {
  testWidgets('the app starts in Arabic, right to left', (tester) async {
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
  });
}
