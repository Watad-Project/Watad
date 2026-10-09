import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_theme.dart';

/// Shows [child] on a scrollable page, with the app theme and the real
/// translations. Arabic (right to left) unless [locale] says otherwise.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Locale locale = AppLocalization.arabic,
}) {
  return pumpLocalizedApp(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
    locale: locale,
  );
}

/// Shows [home] in a `MaterialApp` set up like the real one: app theme,
/// easy_localization with `assets/translations/`, and [locale].
Future<void> pumpLocalizedApp(
  WidgetTester tester,
  Widget home, {
  Locale locale = AppLocalization.arabic,
}) async {
  EasyLocalization.logger.enableLevels = [];
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: AppLocalization.supportedLocales,
      path: AppLocalization.path,
      fallbackLocale: AppLocalization.fallbackLocale,
      startLocale: locale,
      // No SharedPreferences in tests: the locale is set right here.
      saveLocale: false,
      assetLoader: const TestAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: home,
        ),
      ),
    ),
  );
  // The translations load in the first frames.
  await tester.pump();
  await tester.pump();
}

/// Reads the translation files straight from disk. Flutter's asset bundle
/// loads asynchronously, which a widget test's fake clock never finishes.
class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final file = File('$path/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}
