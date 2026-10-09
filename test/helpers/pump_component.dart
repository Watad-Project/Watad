import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/theme/app_theme.dart';

/// Shows [child] on a scrollable page with the app theme, right to left
/// unless [textDirection] says otherwise.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  TextDirection textDirection = TextDirection.rtl,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}
