import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows a spinner that screen readers call loading', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, const Scaffold(body: AppLoadingIndicator()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('جارٍ التحميل'), findsOneWidget);
  });
}
