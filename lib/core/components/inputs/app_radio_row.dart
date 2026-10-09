import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// The color of a selected [AppRadioRow].
enum AppRadioRowAccent {
  /// Orange: payment methods, addresses, choosing a task.
  primary,

  /// Ink: choosing a rejection reason.
  ink,
}

/// One choice in a list of choices, as a bordered row with a round mark at
/// the end. Put several in a column and select one.
class AppRadioRow extends StatelessWidget {
  const AppRadioRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.subtitleTone = AppTone.neutral,
    this.accent = AppRadioRowAccent.primary,
  });

  final String title;
  final bool selected;

  /// Null disables the row.
  final VoidCallback? onTap;
  final String? subtitle;
  final AppTone subtitleTone;
  final AppRadioRowAccent accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent == AppRadioRowAccent.primary
        ? AppColors.primary
        : AppColors.ink;
    final fill = !selected
        ? AppColors.surface
        : accent == AppRadioRowAccent.primary
        ? AppColors.primaryLight
        : AppColors.surfaceMuted;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: fill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: selected ? accentColor : AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.controlHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: AppTextStyles.label),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTextStyles.caption.copyWith(
                              color: subtitleTone.foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accentColor : AppColors.surface,
                      border: selected
                          ? null
                          : Border.all(
                              color: AppColors.controlBorder,
                              width: 2,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
