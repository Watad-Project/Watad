import 'package:flutter/widgets.dart';

/// The app's languages and where their translations live
/// (`assets/translations/ar.json` and `en.json`).
///
/// `main.dart` hands these to easy_localization:
///
/// ```dart
/// EasyLocalization(
///   supportedLocales: AppLocalization.supportedLocales,
///   path: AppLocalization.path,
///   fallbackLocale: AppLocalization.fallbackLocale,
///   child: const WatadApp(),
/// )
/// ```
abstract final class AppLocalization {
  static const String path = 'assets/translations';

  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static const List<Locale> supportedLocales = [arabic, english];

  /// Used when the phone's language is neither Arabic nor English. Arabic,
  /// because the app is built Arabic-first.
  static const Locale fallbackLocale = arabic;
}
