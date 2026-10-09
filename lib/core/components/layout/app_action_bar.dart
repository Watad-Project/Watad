import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The bar of actions at the bottom of a screen. With two buttons, the
/// [primary] one takes two thirds of the width and comes first.
///
/// Pass it as `Scaffold.bottomNavigationBar`; it keeps clear of the system
/// gesture area.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.primary, this.secondary});

  /// Usually an `AppButton`.
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(flex: 2, child: primary),
              if (secondary != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: secondary!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
