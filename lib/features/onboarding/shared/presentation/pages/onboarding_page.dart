import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/onboarding` until GRA-9 builds the three onboarding slides.
/// Replace this page; keep its route in `onboarding_routes.dart`.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
