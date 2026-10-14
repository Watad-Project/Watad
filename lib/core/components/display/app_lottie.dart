import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A Lottie animation from `assets/animations/`, e.g. an onboarding
/// illustration. This is the only place the app imports `lottie`
/// (APP_PACKAGES.md).
///
/// It loops unless [repeat] is false. Without [semanticLabel] it is treated
/// as decoration.
class AppLottie extends StatelessWidget {
  const AppLottie({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.semanticLabel,
  });

  /// The asset path, e.g. `assets/animations/onboarding_all_in_one.json`.
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;

  /// What screen readers say. Without it the animation is decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: Lottie.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        repeat: repeat,
      ),
    );
  }
}
