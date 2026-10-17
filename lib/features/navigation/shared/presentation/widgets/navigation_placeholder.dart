import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The screen of a tab no feature has taken yet.
class NavigationPlaceholder extends StatelessWidget {
  const NavigationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('navigation.coming_soon'),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('navigation_placeholder_post_project_button'),
              label: context.tr('navigation.post_project'),
              icon: Icons.add_circle_outline,
              onPressed: () =>
                  context.pushNamed(ClientProjectsRoutes.postProjectName),
            ),
          ],
        ),
      ),
    );
  }
}
