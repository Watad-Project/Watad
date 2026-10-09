import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The label above a field. Required fields get a red "Required" at the end
/// of the line.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 14)),
        ),
        if (isRequired)
          Text(
            context.tr('common.required'),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
          ),
      ],
    );
  }
}
