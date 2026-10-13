import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';

/// The screen of a tab whose feature isn't built yet.
class NavigationPlaceholder extends StatelessWidget {
  const NavigationPlaceholder({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppStatusCard(
          tone: AppTone.neutral,
          title: context.tr('navigation.coming_soon'),
          subtitle: context.tr('navigation.coming_soon_description'),
        ),
      ),
    );
  }
}
