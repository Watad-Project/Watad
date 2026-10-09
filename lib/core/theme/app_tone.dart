import 'package:flutter/painting.dart';
import 'package:watad/core/theme/app_colors.dart';

/// The four status tones of the design sheet: orange waits for an action,
/// green is done, red is rejected and gray is neutral.
///
/// Badges, tags, status cards and option subtitles take a tone instead of
/// colors, so a status looks the same everywhere.
enum AppTone { attention, success, danger, neutral }

/// The colors of each [AppTone].
extension AppToneColors on AppTone {
  /// Light fill of cards, tags and selected rows.
  Color get background => switch (this) {
    AppTone.attention => AppColors.primaryLight,
    AppTone.success => AppColors.successLight,
    AppTone.danger => AppColors.errorLight,
    AppTone.neutral => AppColors.neutralLight,
  };

  /// Fill of a status badge (a little stronger for [AppTone.attention]).
  Color get badgeBackground => switch (this) {
    AppTone.attention => AppColors.primarySoft,
    _ => background,
  };

  /// Text on [background] or [badgeBackground].
  Color get foreground => switch (this) {
    AppTone.attention => AppColors.primaryDark,
    AppTone.success => AppColors.successDark,
    AppTone.danger => AppColors.error,
    AppTone.neutral => AppColors.textBody,
  };

  /// Outline of a status card.
  Color get border => switch (this) {
    AppTone.attention => AppColors.primaryBorder,
    AppTone.success => AppColors.successBorder,
    AppTone.danger => AppColors.errorBorder,
    AppTone.neutral => AppColors.borderStrong,
  };

  /// Solid marks: status dots and the square icon of a tag.
  Color get accent => switch (this) {
    AppTone.attention => AppColors.primary,
    AppTone.success => AppColors.success,
    AppTone.danger => AppColors.error,
    AppTone.neutral => AppColors.textSecondary,
  };
}
