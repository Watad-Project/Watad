import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder for `/auth/signup/business` until GRA-13 builds the business sign-up screen.
/// Replace this page; keep its route in `auth_routes.dart`.
class SignUpBusinessPage extends StatelessWidget {
  const SignUpBusinessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.tr('common.coming_soon'))),
    );
  }
}
