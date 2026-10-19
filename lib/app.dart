import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:watad/core/components/layout/app_keyboard_dismiss.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/core/theme/app_theme.dart';

/// The app: theme, router, the language from easy_localization, and the
/// keyboard closing on a tap outside its field.
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
      localizationsDelegates: [
        ...context.localizationDelegates,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // Around every page, dialog and sheet: a tap outside a text field or a
      // drag on a list closes the keyboard (APP_ARCHITECTURE.md §10).
      builder: (context, child) =>
          AppKeyboardDismiss(child: child ?? const SizedBox.shrink()),
    );
  }
}
