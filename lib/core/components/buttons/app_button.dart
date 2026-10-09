import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The look of an [AppButton].
enum AppButtonVariant {
  /// Orange: the one main action of a screen.
  primary,

  /// White with an outline: the other choice next to a primary button.
  secondary,

  /// Ink: confirming a rejection or another serious action.
  dark,

  /// Orange text without a box, e.g. "See all".
  link,
}

/// Every button in the app.
///
/// It is disabled when [onPressed] is null and shows a spinner instead of its
/// label while [isLoading] is true (taps are ignored meanwhile). Buttons fill
/// the width of their parent, except [AppButtonVariant.link].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  /// Shown before the label.
  final IconData? icon;

  /// Shown after the label, e.g. an arrow on a link. Directional icons such
  /// as [Icons.arrow_forward] flip in RTL by themselves.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final child = isLoading ? _spinner() : _content();
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: onTap,
        // While loading, keep the full orange instead of the disabled one.
        style: isLoading
            ? FilledButton.styleFrom(disabledBackgroundColor: AppColors.primary)
            : null,
        child: child,
      ),
      AppButtonVariant.dark => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          disabledBackgroundColor: isLoading
              ? AppColors.ink
              : AppColors.ink.withValues(alpha: 0.4),
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        child: child,
      ),
      AppButtonVariant.link => TextButton(onPressed: onTap, child: child),
    };
    if (variant == AppButtonVariant.link) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _content() {
    if (icon == null && trailingIcon == null) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );
  }

  Widget _spinner() {
    final color = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.dark => AppColors.white,
      AppButtonVariant.secondary => AppColors.ink,
      AppButtonVariant.link => AppColors.primary,
    };
    return SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
