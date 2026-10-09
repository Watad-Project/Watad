import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// What goes inside a Watad snack bar: white text on ink, with a small icon
/// in the tone's color when the message is good or bad news.
///
/// You won't build this by hand. Use the [AppSnackBarContext] methods on
/// `context` instead.
class AppSnackBar extends StatelessWidget {
  const AppSnackBar({
    super.key,
    required this.message,
    this.tone = AppTone.neutral,
  });

  final String message;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final icon = switch (tone) {
      AppTone.success => Icons.check_circle,
      AppTone.danger => Icons.error,
      AppTone.attention => Icons.info,
      AppTone.neutral => null,
    };
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: tone.accent),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Snack bars from any widget under the app's `MaterialApp`:
///
/// ```dart
/// context.showSuccessSnackBar('addresses.saved'.tr());
///
/// context.showErrorSnackBar(
///   failure.messageKey.tr(),
///   actionLabel: 'common.retry'.tr(),
///   onAction: _reload,
/// );
/// ```
///
/// A new snack bar replaces the one on screen, so a fast double tap doesn't
/// queue up two "Saved" messages.
///
/// After an `await`, check `context.mounted` before calling these. The
/// screen may be gone by then.
///
/// ## Writing the message
///
/// Write it the way you'd say it to the person, in one short sentence:
///
/// - Say what happened: "Address saved", not "Operation completed
///   successfully".
/// - For a problem, say what went wrong and what they can do about it:
///   "No internet. Check your connection and try again." Error messages come
///   from `Failure.messageKey` (the `errors` group), so they read the same
///   everywhere.
/// - No "Error:" prefix, no codes, no exclamation marks.
/// - Leave out what the screen already shows. If the new item is already in
///   the list, "Added" is enough.
extension AppSnackBarContext on BuildContext {
  /// Shows [message] for [duration].
  ///
  /// With an action ([actionLabel] and [onAction] together), the snack bar
  /// stays until it is tapped or swiped away. That is Flutter's default, so
  /// people using a screen reader have time to reach the button.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    AppTone tone = AppTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    assert(
      (actionLabel == null) == (onAction == null),
      'Pass actionLabel and onAction together.',
    );
    final messenger = ScaffoldMessenger.of(this)..hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: AppSnackBar(message: message, tone: tone),
        duration: duration,
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction!),
      ),
    );
  }

  /// Good news, with a green check: "Address saved".
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String message,
  ) {
    return showSnackBar(message, tone: AppTone.success);
  }

  /// Something went wrong, with a red mark. It stays 6 seconds instead of 4,
  /// because people read a problem more slowly than a confirmation.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showSnackBar(
      message,
      tone: AppTone.danger,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 6),
    );
  }

  /// Hides the snack bar on screen, if there is one.
  void hideSnackBar() => ScaffoldMessenger.of(this).hideCurrentSnackBar();
}
