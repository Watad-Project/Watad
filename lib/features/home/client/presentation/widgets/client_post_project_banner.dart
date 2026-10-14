import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

class ClientPostProjectBanner extends StatelessWidget {
  const ClientPostProjectBanner({this.onStartNowTap, super.key});

  final VoidCallback? onStartNowTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.post_project_title'.tr(),
              style: AppTextStyles.h2.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'home.post_project_subtitle'.tr(),
              style: AppTextStyles.body.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onStartNowTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                'home.start_now'.tr(),
                style: AppTextStyles.label.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
