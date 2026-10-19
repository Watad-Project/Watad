import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The orange «انشر مشروعاً» card. «ابدأ الآن» opens the post-project flow
/// (GRA-18).
class ClientPostProjectBanner extends StatelessWidget {
  const ClientPostProjectBanner({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('home.post_project_title'),
            style: AppTextStyles.h1.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.tr('home.post_project_subtitle'),
            style: AppTextStyles.body.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: context.tr('home.start_now'),
            variant: AppButtonVariant.secondary,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
