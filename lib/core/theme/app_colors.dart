import 'package:flutter/painting.dart';

/// The Watad color tokens.
///
/// The first group is the color card ("الألوان") of the design sheet. The
/// second group is not on that card: it was measured from the component
/// screenshots of the same sheet (borders, badge tones, control states).
///
/// Features never write a color literal (the checker rejects it); they use
/// `Theme.of(context)` or these tokens.
abstract final class AppColors {
  // The design sheet's color card.

  /// Orange: the only color for the main action.
  static const Color primary = Color(0xFFE8722C);

  /// Ink: headings and dark buttons.
  static const Color ink = Color(0xFF1C1A18);

  /// Paragraph text: descriptions and notes.
  static const Color textBody = Color(0xFF6B645E);

  /// Secondary text: dates and hints.
  static const Color textSecondary = Color(0xFF9A938C);

  /// Light orange: selection and the pending state.
  static const Color primaryLight = Color(0xFFFFF6F0);

  /// Light green: verification and acceptance.
  static const Color successLight = Color(0xFFF4F7F5);

  /// Light red: rejection and its reason.
  static const Color errorLight = Color(0xFFFDF3F2);

  // Measured from the component screenshots of the design sheet.

  static const Color white = Color(0xFFFFFFFF);

  /// Screens, cards, fields, dialogs and sheets.
  static const Color surface = white;

  /// Quiet panels inside a card: key-value lists, cart headers and a
  /// selected reject reason.
  static const Color surfaceMuted = Color(0xFFFAF7F4);

  /// Orange badges and icon tiles, a little stronger than [primaryLight].
  static const Color primarySoft = Color(0xFFFFF1E5);

  /// Orange text on [primaryLight] and [primarySoft].
  static const Color primaryDark = Color(0xFFB15713);

  /// A disabled primary button.
  static const Color primaryDisabled = Color(0xFFF5C6AC);

  /// Outline of a pending status card.
  static const Color primaryBorder = Color(0xFFF8CEB5);

  /// Verified checks and the "done" dot.
  static const Color success = Color(0xFF24895B);

  /// Green text on [successLight].
  static const Color successDark = Color(0xFF326A4F);

  /// Outline of an accepted status card.
  static const Color successBorder = Color(0xFFB5D6C7);

  /// Field errors, the "required" mark and red text on [errorLight].
  static const Color error = Color(0xFFBF3C2F);

  /// Outline of a rejected status card.
  static const Color errorBorder = Color(0xFFEBBCB6);

  /// Gray badges (draft, waiting) and neutral icon tiles.
  static const Color neutralLight = Color(0xFFF1EDE9);

  /// Card outlines and dividers.
  static const Color border = Color(0xFFE8E8E8);

  /// Text fields, secondary buttons and steppers.
  static const Color borderStrong = Color(0xFFE0E0E0);

  /// Unselected radio buttons and checkboxes.
  static const Color controlBorder = Color(0xFFCEC7C0);

  /// The track of a switch that is off.
  static const Color controlOff = Color(0xFFDCD5CE);

  /// The empty part of progress bars, steppers and timelines.
  static const Color track = Color(0xFFEEE8E2);

  /// Image placeholders, with [placeholderStripe] for the diagonal stripes.
  static const Color placeholder = Color(0xFFECE7E2);

  static const Color placeholderStripe = Color(0xFFE3DDD6);
}
