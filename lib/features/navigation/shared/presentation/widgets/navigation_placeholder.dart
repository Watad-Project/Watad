import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The screen of a tab no feature has taken yet.
class NavigationPlaceholder extends StatelessWidget {
  const NavigationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          context.tr('navigation.coming_soon'),
          style: AppTextStyles.caption,
        ),
      ),
    );
  }
}
