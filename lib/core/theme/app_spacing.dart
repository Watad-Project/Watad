/// Spacing, corner radii and control sizes, measured from the design sheet.
library;

/// Gaps and paddings. Use these instead of literal numbers.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii.
abstract final class AppRadius {
  /// Checkboxes.
  static const double xs = 4;

  /// Small tiles and thumbnails.
  static const double sm = 8;

  /// Panels inside a card, segmented tabs, menus and snack bars.
  static const double md = 12;

  /// Buttons, text fields, selects, cards and photo tiles.
  static const double lg = 14;

  /// Dialogs and bottom sheets.
  static const double xl = 20;

  /// Fully round ends: chips, badges and switches.
  static const double pill = 999;
}

/// Fixed sizes of controls.
abstract final class AppSizes {
  /// Buttons, text fields and selects.
  static const double controlHeight = 56;

  /// The smallest tap target allowed (APP_COMPONENTS.md §2).
  static const double minTapTarget = 48;
}
