import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// An on/off switch. With a [label] it is a full-width row (label at the
/// start, switch at the end) that toggles when any part of it is tapped.
///
/// It is disabled when [onChanged] is null.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  /// What screen readers say for a switch without a [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final control = Switch(value: value, onChanged: onChanged);
    if (label == null) {
      return Semantics(label: semanticLabel, child: control);
    }
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              control,
            ],
          ),
        ),
      ),
    );
  }
}
