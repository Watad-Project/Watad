import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The states something goes through, in a row, with the reached ones in
/// orange, e.g. a task: proposed → accepted → done → approved → paid.
///
/// The caller passes the translated [labels] in order and the index of the
/// current state.
///
/// With [animateFrom], the reached states fill in from that index to
/// [currentIndex] when the stepper first shows, and fill on to a new
/// [currentIndex] when it changes: the dots turn orange one after another
/// and the line between them fills, with the app's motion ([AppMotion]).
/// Nothing waits for it, and the states show at once when the phone asks to
/// reduce motion.
class AppStateStepper extends StatelessWidget {
  const AppStateStepper({
    super.key,
    required this.labels,
    required this.currentIndex,
    this.animateFrom,
  });

  final List<String> labels;
  final int currentIndex;

  /// The state the fill starts from, e.g. 0. Null (the default): the states
  /// show as they are, without a fill, and the lines stay gray.
  final int? animateFrom;

  @override
  Widget build(BuildContext context) {
    final from = animateFrom;
    final end = currentIndex.toDouble();
    if (from == null) {
      return _Steps(
        labels: labels,
        currentIndex: currentIndex,
        progress: end,
        fillsLines: false,
      );
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      return _Steps(
        labels: labels,
        currentIndex: currentIndex,
        progress: end,
        fillsLines: true,
      );
    }
    // Runs from [from] when it first shows, and from wherever it is to a
    // new [currentIndex].
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: end),
      duration: AppMotion.enter * 2,
      curve: AppMotion.enterCurve,
      builder: (context, progress, _) => _Steps(
        labels: labels,
        currentIndex: currentIndex,
        progress: progress,
        fillsLines: true,
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({
    required this.labels,
    required this.currentIndex,
    required this.progress,
    required this.fillsLines,
  });

  final List<String> labels;

  /// The selected state, for screen readers.
  final int currentIndex;

  /// How far the fill has gone: state `i` is reached once it is `i` or more.
  final double progress;

  /// Whether the lines between reached states turn orange.
  final bool fillsLines;

  @override
  Widget build(BuildContext context) {
    final last = labels.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == currentIndex,
              child: Column(
                children: [
                  Row(
                    children: [
                      // The half line before a dot fills in the second half
                      // of the way from the state before; the half after it,
                      // in the first half of the way to the next.
                      Expanded(
                        child: i == 0
                            ? const SizedBox()
                            : _Line(
                                fill: fillsLines ? progress - i + 0.5 : null,
                              ),
                      ),
                      _Dot(isReached: progress >= i),
                      Expanded(
                        child: i == last
                            ? const SizedBox()
                            : _Line(fill: fillsLines ? progress - i : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs + 2),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: progress >= i
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: progress >= i
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Half the line between two dots: gray, and orange from its start for its
/// share of the fill.
class _Line extends StatelessWidget {
  const _Line({required this.fill});

  /// Half of a state's way, so 0.5 fills it. Null: it never fills.
  final double? fill;

  @override
  Widget build(BuildContext context) {
    final share = fill;
    return SizedBox(
      height: 2,
      child: ColoredBox(
        color: AppColors.track,
        child: share == null
            ? null
            : FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: (share * 2).clamp(0.0, 1.0),
                child: const ColoredBox(color: AppColors.primary),
              ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isReached});

  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isReached ? AppColors.primary : AppColors.surface,
        border: isReached
            ? null
            : Border.all(color: AppColors.controlBorder, width: 2),
      ),
    );
  }
}
