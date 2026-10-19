import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/localization/app_translations_loader.dart';

/// The app's languages, where their translations live (one file per group
/// and language in `assets/translations/`, read by [AppTranslationsLoader]),
/// and the easy_localization setup around the app.
abstract final class AppLocalization {
  static const String path = 'assets/translations';

  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static const List<Locale> supportedLocales = [arabic, english];

  /// Used when a translation file can't be matched to the phone's language.
  static const Locale fallbackLocale = arabic;

  /// Puts easy_localization above [child], the whole app in `main.dart`.
  ///
  /// The first launch is in Arabic. After that the app opens in the
  /// language the person picked last, saved on the phone.
  ///
  /// Tests pass their own [assetLoader] and turn off [saveLocale], so they
  /// read the translation files from disk and never touch the phone's
  /// storage.
  static Widget scope({
    required Widget child,
    AssetLoader assetLoader = const AppTranslationsLoader(),
    bool saveLocale = true,
  }) {
    return EasyLocalization(
      supportedLocales: supportedLocales,
      path: path,
      fallbackLocale: fallbackLocale,
      startLocale: arabic,
      saveLocale: saveLocale,
      assetLoader: assetLoader,
      // Each language's own plural forms (Arabic has six: «٣ تقييمات»,
      // «٦٤ تقييمًا»). easy_localization's default uses only zero, one,
      // two and other.
      ignorePluralRules: false,
      child: child,
    );
  }
}

/// Reading and changing the app's language from any widget.
///
/// Arabic runs right to left and English left to right by itself: screens
/// don't do anything for it.
extension AppLanguage on BuildContext {
  bool get isArabic =>
      locale.languageCode == AppLocalization.arabic.languageCode;

  /// Switches the whole app to [newLocale] and remembers it for the next
  /// launch.
  Future<void> changeLanguage(Locale newLocale) => setLocale(newLocale);

  /// Arabic to English and back, for a language button.
  Future<void> toggleLanguage() => changeLanguage(
    isArabic ? AppLocalization.english : AppLocalization.arabic,
  );

  /// [value] written for the app's language, with exactly [decimals] digits
  /// after the point: «٤٦٥٬٠٠٠» and «٤٫٨» in Arabic, "465,000" and "4.8" in
  /// English.
  String formatNumber(num value, {int decimals = 0}) {
    return NumberFormat.decimalPatternDigits(
      // intl's plain 'ar' writes Western digits; 'ar_EG' writes the
      // Arabic-Indic digits and separators of the designs.
      locale: isArabic ? 'ar_EG' : AppLocalization.english.languageCode,
      decimalDigits: decimals,
    ).format(value);
  }
}
