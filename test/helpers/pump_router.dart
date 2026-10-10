import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/core/theme/app_theme.dart';

import 'pump_component.dart';

/// Shows a fresh app router in a localized app, set up like `WatadApp`, and
/// returns it. Route tests navigate with it, e.g.
/// `router.goNamed(AuthRoutes.loginName)`.
Future<GoRouter> pumpAppRouter(WidgetTester tester) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    AppLocalization.scope(
      assetLoader: const TestAssetLoader(),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// The path [router] shows now.
String currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;
