import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/auth/role` until GRA-11 builds the role selection screen.
/// Replace this page; keep its route in `auth_routes.dart`.
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
