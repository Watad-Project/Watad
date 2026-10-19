import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';

/// Opens dialogs and bottom sheets with the app's motion ([AppMotion]): a
/// dialog fades in while it grows from 94%, a sheet slides up and settles,
/// and both leave a little faster than they came.
///
/// Open every popup through here instead of `showDialog` or
/// `showModalBottomSheet`, so they all move the same way:
///
/// ```dart
/// AppPopup.dialog<void>(context, builder: (_) => const MyDialog());
/// AppPopup.sheet<void>(context, builder: (_) => const MySheetContent());
/// ```
abstract final class AppPopup {
  /// The size a dialog grows from.
  static const double _dialogStartScale = 0.94;

  /// Shows [builder]'s widget (usually a `Dialog`) over a dimmed page. A tap
  /// outside closes it unless [barrierDismissible] is false. [useSafeArea]
  /// keeps it clear of the notch; full-screen viewers turn it off.
  static Future<T?> dialog<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? barrierColor,
    bool barrierDismissible = true,
    bool useSafeArea = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? AppColors.ink.withValues(alpha: 0.5),
      transitionDuration: AppMotion.enter,
      pageBuilder: (context, _, _) {
        final dialog = Builder(builder: builder);
        return useSafeArea ? SafeArea(child: dialog) : dialog;
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enterCurve,
          reverseCurve: AppMotion.exitCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: _dialogStartScale, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Shows [builder]'s widget in a sheet from the bottom, with the drag
  /// handle. It grows with its content up to the safe area; make the
  /// content scrollable when it can be long.
  static Future<T?> sheet<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AppMotion.popup,
      builder: builder,
    );
  }
}
