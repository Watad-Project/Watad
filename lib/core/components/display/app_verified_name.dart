import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A name followed by the green check of a verified business.
class AppVerifiedName extends StatelessWidget {
  const AppVerifiedName({
    super.key,
    required this.name,
    this.style = AppTextStyles.h2,
    this.semanticLabel,
  });

  final String name;
  final TextStyle style;

  /// What screen readers say for the check. Defaults to "Verified".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconSize = (style.fontSize ?? 16) + 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs + 2),
        Icon(
          Icons.check_circle,
          size: iconSize,
          color: AppColors.success,
          semanticLabel: semanticLabel ?? context.tr('common.verified'),
        ),
      ],
    );
  }
}
