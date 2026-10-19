import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// «ابحث عن مقاول أو مادة». Search has no screen yet (GRA-23 keeps it
/// inactive), so this only shows where it will be.
class ClientSearchBar extends StatelessWidget {
  const ClientSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.controlHeight,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.tr('home.search_hint'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
