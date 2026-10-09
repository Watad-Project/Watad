import 'package:flutter/painting.dart';
import 'package:watad/core/theme/app_colors.dart';

/// The Watad type scale, in IBM Plex Sans Arabic and IBM Plex Mono
/// (bundled in `assets/fonts/`).
///
/// The sizes are the design sheet's sizes × 4/3, because the sheet was
/// exported at 75%: h1 18 → 24, h2 13.5 → 18, body 12 → 16 and
/// caption 11 → 14.
abstract final class AppTextStyles {
  static const String fontFamily = 'IBMPlexSansArabic';
  static const String monoFontFamily = 'IBMPlexMono';

  /// Screen titles.
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.ink,
  );

  /// Section and card titles.
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  /// Paragraphs and descriptions inside cards and forms.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.7,
    color: AppColors.textBody,
  );

  /// Dates, hints and other secondary facts.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Buttons, field labels and other strong one-line text.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  /// Badges, chips and small tags.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  /// Values people read digit by digit: commercial registration, IBAN,
  /// phone numbers and ledger hashes.
  static const TextStyle mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );
}
