import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.note,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String description;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.primary;
    final fill = selected ? AppColors.primaryLight : AppColors.surface;
    final border = selected ? accentColor : AppColors.border;
    final borderWidth = selected ? 1.5 : 1.0;

    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        color: fill,
        borderColor: border,
        borderWidth: borderWidth,
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySoft
                          : AppColors.neutralLight,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadius.md),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? AppColors.primary : AppColors.ink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: Text(title, style: AppTextStyles.h2)),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accentColor : AppColors.surface,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.controlBorder, width: 2),
                  ),
                  child: selected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              note,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
