import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/auth/signup/client` until GRA-12 builds the client sign-up screen.
/// Replace this page; keep its route in `auth_routes.dart`.
class SignUpClientPage extends StatelessWidget {
  const SignUpClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
