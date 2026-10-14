import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_lottie.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// One onboarding slide: the animation on a band across the top, then the
/// title and the description.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.animation,
    required this.title,
    required this.description,
    super.key,
  });

  /// The Lottie file in `assets/animations/`.
  final String animation;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: ColoredBox(
            color: AppColors.surfaceMuted,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppLottie(asset: animation),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
