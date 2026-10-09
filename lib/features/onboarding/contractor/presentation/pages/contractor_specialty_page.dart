import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/contractor/onboarding/specialty` until GRA-16 builds the contractor specialty screen.
/// Replace this page; keep its route in `contractor_onboarding_routes.dart`.
class ContractorSpecialtyPage extends StatelessWidget {
  const ContractorSpecialtyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
