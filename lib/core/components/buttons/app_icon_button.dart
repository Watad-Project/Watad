import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The look of an [AppIconButton].
enum AppIconButtonVariant {
  /// Just the icon, in ink: back arrows and toolbar actions.
  plain,

  /// A white icon on an orange square: "add" on a market tile.
  filled,
}

/// An icon-only button. [tooltip] is required: it is what screen readers say.
///
/// The tap target is always at least 48×48.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.plain,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppIconButtonVariant.plain => IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        color: AppColors.ink,
        onPressed: onPressed,
      ),
      AppIconButtonVariant.filled => IconButton.filled(
        icon: Icon(icon, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.white,
          fixedSize: const Size.square(40),
          minimumSize: const Size.square(40),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    };
  }
}
