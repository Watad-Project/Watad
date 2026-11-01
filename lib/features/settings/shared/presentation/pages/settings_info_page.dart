import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// «عن وتد», «الشروط» or «الخصوصية»: static text.
class SettingsInfoPage extends StatelessWidget {
  const SettingsInfoPage({required this.page, super.key});

  /// `about`, `terms` or `privacy`, from the route; anything else shows
  /// «عن وتد».
  final String page;

  static const List<String> pages = ['about', 'terms', 'privacy'];

  @override
  Widget build(BuildContext context) {
    final key = pages.contains(page) ? page : 'about';
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('settings.$key'),
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(context.tr('settings.${key}_body'), style: AppTextStyles.body),
        ],
      ),
    );
  }
}
