import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/splash` until GRA-8 builds the splash screen.
/// Replace this page; keep its route in `splash_routes.dart`.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
