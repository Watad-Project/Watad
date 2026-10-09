import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The bar at the top of every sub-screen: a back arrow and a quiet title.
///
/// The arrow points right in Arabic and left in English. Its tooltip comes
/// from Flutter's own translations.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.onBack, this.actions});

  final String title;

  /// Null hides the back arrow.
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : AppIconButton(
              icon: Icons.arrow_back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
            ),
      titleSpacing: onBack == null ? AppSpacing.md : 0,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
    );
  }
}
