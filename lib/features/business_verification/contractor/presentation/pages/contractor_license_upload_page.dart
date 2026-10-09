import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/contractor/business-verification/license` until GRA-14 builds the contractor license upload screen.
/// Replace this page; keep its route in `contractor_business_verification_routes.dart`.
class ContractorLicenseUploadPage extends StatelessWidget {
  const ContractorLicenseUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
