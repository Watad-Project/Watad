import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The loading shimmer: a soft light sweeping over [child], from the start of
/// the line to its end (right to left in Arabic). Build [child] from
/// [AppSkeletonBox]es shaped like the content that is coming, e.g. a card's
/// title, caption and buttons.
///
/// With "reduce motion" on, the boxes show without the sweep.
class AppShimmer extends StatefulWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skeleton = Semantics(
      label: context.tr('common.loading'),
      child: ExcludeSemantics(child: widget.child),
    );
    if (MediaQuery.disableAnimationsOf(context)) return skeleton;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _sweep,
      child: skeleton,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            AppColors.placeholder,
            AppColors.surfaceMuted,
            AppColors.placeholder,
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _Sweep(_sweep.value, isRtl: isRtl),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

/// Moves the gradient's light band across the box, from one side past the
/// other.
class _Sweep extends GradientTransform {
  const _Sweep(this.progress, {required this.isRtl});

  final double progress;
  final bool isRtl;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final offset = bounds.width * (progress * 2 - 1);
    return Matrix4.translationValues(isRtl ? -offset : offset, 0, 0);
  }
}

/// One gray shape of a loading skeleton, inside an [AppShimmer]. Without a
/// [width] it takes the whole line.
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    required this.height,
    this.width,
    this.radius = AppRadius.sm,
    super.key,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
