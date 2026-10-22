import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One slice of an [AppDonutChart]: what it is, how many, and the text of
/// that number in the app's language.
class AppDonutSlice {
  const AppDonutSlice({
    required this.label,
    required this.value,
    required this.valueLabel,
  });

  final String label;
  final int value;

  /// [value] written for the app's language, e.g. «٥٧ · ١٤٪».
  final String valueLabel;
}

/// A part-to-whole ring: one slice per category, the total in the middle,
/// and a legend that names every slice with its number, so nothing is told
/// by color alone.
///
/// Slices take [AppChartColors.series] in order, at most five. A whole of
/// zero draws an empty track.
class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.size = 168,
    super.key,
  });

  final List<AppDonutSlice> slices;

  /// The total, written for the app's language, and what it counts.
  final String centerValue;
  final String centerLabel;

  /// The ring's width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    assert(
      slices.length <= AppChartColors.series.length,
      'At most five slices; fold the rest into one',
    );
    final values = [for (final slice in slices) slice.value];
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: [
            '$centerLabel $centerValue',
            for (final slice in slices) '${slice.label} ${slice.valueLabel}',
          ].join('\n'),
          excludeSemantics: true,
          child: Center(
            child: SizedBox.square(
              dimension: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: animate ? 0 : 1, end: 1),
                duration: AppMotion.enter * 2,
                curve: AppMotion.enterCurve,
                builder: (context, progress, child) => CustomPaint(
                  painter: _DonutPainter(
                    values: values,
                    progress: progress,
                    textDirection: Directionality.of(context),
                  ),
                  child: child,
                ),
                // The total, scaled down to fit inside the ring.
                child: Padding(
                  padding: EdgeInsets.all(size * 0.2),
                  child: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(centerValue, style: AppTextStyles.h1),
                        Text(centerLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < slices.length; i++)
          _LegendRow(slice: slices[i], color: AppChartColors.series[i]),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.color});

  final AppDonutSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(3)),
            ),
            child: const SizedBox.square(dimension: 12),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(slice.label, style: AppTextStyles.body)),
          const SizedBox(width: AppSpacing.xs),
          // The number wears the text color; the square beside it carries
          // the slice's color.
          Text(slice.valueLabel, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

/// The ring: slices clockwise from the top in RTL's reading order, with a
/// thin gap of the surface between them.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.progress,
    required this.textDirection,
  });

  final List<int> values;

  /// 0 to 1, how much of the ring is drawn (it sweeps in once).
  final double progress;
  final TextDirection textDirection;

  static const double _thickness = 22;

  /// The surface gap between two slices, in pixels along the ring.
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - _thickness) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;

    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        stroke..color = AppColors.track,
      );
      return;
    }
    // In RTL the ring reads the other way round, like the text.
    final direction = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    final gapAngle = _gap / radius;
    final drawn = values.where((value) => value > 0).length;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = math.pi * 2 * values[i] / total * progress;
      final visible = drawn > 1 ? math.max(0.0, sweep - gapAngle) : sweep;
      canvas.drawArc(
        rect,
        start,
        visible * direction,
        false,
        stroke..color = AppChartColors.series[i],
      );
      start += sweep * direction;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.textDirection != textDirection ||
      !_sameValues(oldDelegate.values, values);

  static bool _sameValues(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
