import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// What the router shows for an address that doesn't exist: "We couldn't
/// find this page" and a button back to the start.
class AppNotFoundView extends StatelessWidget {
  const AppNotFoundView({super.key, required this.onBackToStart});

  final VoidCallback onBackToStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('common.page_not_found'),
              textAlign: TextAlign.center,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.tr('common.back_to_start'),
              onPressed: onBackToStart,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
