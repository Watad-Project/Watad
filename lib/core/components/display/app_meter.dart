import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One share of a whole as a bar: «٥٨٨ من ٦٤٠ معروضة الآن», with the bar
/// filled that far. For a single ratio, instead of a pie of two slices.
class AppMeter extends StatelessWidget {
  const AppMeter({
    required this.label,
    required this.valueLabel,
    required this.fraction,
    super.key,
  });

  /// What the share is, e.g. «معروضة الآن».
  final String label;

  /// The share in words, for the app's language, e.g. «٥٨٨ من ٦٤٠ · ٩٢٪».
  final String valueLabel;

  /// 0 to 1; anything outside is clamped.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $valueLabel',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  valueLabel,
                  style: AppTextStyles.label,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              color: AppChartColors.meterFill,
              backgroundColor: AppChartColors.meterTrack,
            ),
          ),
        ],
      ),
    );
  }
}
