import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/core/theme/app_theme.dart';

/// The app: theme, router and the language from easy_localization.
///
/// It must sit under `AppLocalization.scope` (see `main.dart`), which gives
/// it the current locale. Arabic then runs right to left and English left
/// to right everywhere, without any work in the screens.
class WatadApp extends StatelessWidget {
  const WatadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.tr('common.app_name'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
