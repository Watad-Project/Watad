import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/localization/app_translations_loader.dart';
import 'package:watad/core/theme/app_theme.dart';

/// Shows [child] on a scrollable page, with the app theme and the real
/// translations. Arabic (right to left) unless [locale] says otherwise.
/// [textScale] and [boldText] act like the phone's text settings.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Locale locale = AppLocalization.arabic,
  double textScale = 1,
  bool boldText = false,
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
    textScale: textScale,
    boldText: boldText,
  );
}

/// Shows [home] in a `MaterialApp` set up like the real one: app theme,
/// easy_localization with `assets/translations/`, and [locale].
///
/// [textScale] and [boldText] act like the phone's text settings: use
/// `textScale: largeTextScale, boldText: true` to check a screen doesn't
/// overflow with large, bold text (APP_ARCHITECTURE.md §10).
Future<void> pumpLocalizedApp(
  WidgetTester tester,
  Widget home, {
  Locale locale = AppLocalization.arabic,
  double textScale = 1,
  bool boldText = false,
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
      // As in AppLocalization.scope.
      ignorePluralRules: false,
      assetLoader: const TestAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          builder: (context, child) => withTextSettings(
            context,
            child ?? const SizedBox.shrink(),
            textScale: textScale,
            boldText: boldText,
          ),
          home: home,
        ),
      ),
    ),
  );
  // The translations load in the first frames.
  await tester.pump();
  await tester.pump();
}

/// Reads the translation files straight from disk, grouped exactly like
/// `AppTranslationsLoader` does in the app. Flutter's asset bundle loads
/// asynchronously, which a widget test's fake clock never finishes.
class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final translations = <String, dynamic>{};
    for (final file in Directory(path).listSync().whereType<File>()) {
      final group = AppTranslationsLoader.groupOf(
        file.uri.pathSegments.last,
        locale.languageCode,
      );
      if (group != null) {
        translations[group] = jsonDecode(file.readAsStringSync());
      }
    }
    return translations;
  }
}

/// The largest text size screens must handle: 200%, the most phones offer
/// (APP_ARCHITECTURE.md §10).
const double largeTextScale = 2;

/// [child] with the phone's text size and bold-text setting replaced.
Widget withTextSettings(
  BuildContext context,
  Widget child, {
  double textScale = 1,
  bool boldText = false,
}) {
  if (textScale == 1 && !boldText) return child;
  return MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale), boldText: boldText),
    child: child,
  );
}
