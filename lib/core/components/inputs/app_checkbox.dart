import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A checkbox with its label, e.g. accepting the terms. Tapping the label
/// toggles it too.
///
/// It is disabled when [onChanged] is null.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final toggle = onChanged == null ? null : () => onChanged!(!value);
    return MergeSemantics(
      child: InkWell(
        onTap: toggle,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: toggle == null ? null : (_) => toggle(),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
