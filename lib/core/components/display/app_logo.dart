import 'package:flutter/material.dart';

/// The Watad logo: navy and orange on light surfaces, white and orange on
/// dark ones ([onDark]).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 64,
    this.onDark = false,
    this.semanticLabel,
  });

  static const String lightAsset = 'assets/images/logo.png';
  static const String darkAsset = 'assets/images/logo_on_dark.png';

  final double height;
  final bool onDark;

  /// What screen readers say, e.g. the app name. Without it the logo is
  /// treated as decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onDark ? darkAsset : lightAsset,
      height: height,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
