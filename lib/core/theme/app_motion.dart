import 'package:flutter/animation.dart';

/// How things move. One set of durations and curves, so every dialog, sheet,
/// snack bar and loading state appears and goes away the same way.
abstract final class AppMotion {
  /// Something appearing: a dialog, a sheet, a snack bar, content after
  /// loading.
  static const Duration enter = Duration(milliseconds: 280);

  /// Something going away, a little faster than it came.
  static const Duration exit = Duration(milliseconds: 200);

  /// One sweep of the loading shimmer.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Starts fast and settles gently.
  static const Curve enterCurve = Curves.easeOutCubic;

  /// Starts gently and leaves fast.
  static const Curve exitCurve = Curves.easeInCubic;

  /// For Flutter's `sheetAnimationStyle` and `snackBarAnimationStyle`.
  static const AnimationStyle popup = AnimationStyle(
    duration: enter,
    reverseDuration: exit,
    curve: enterCurve,
    reverseCurve: exitCurve,
  );
}
