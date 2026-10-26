import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('AppConfirmDialog.show returns empty string when confirmed', (
    tester,
  ) async {
    String? result;
    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppConfirmDialog.show(
                context,
                title: 'سحب العرض',
                message: 'هل أنت متأكد من سحب العرض؟',
                confirmLabel: 'سحب',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('سحب العرض'), findsOneWidget);
    expect(find.text('هل أنت متأكد من سحب العرض؟'), findsOneWidget);

    await tester.tap(find.text('سحب'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, isEmpty);
  });

  testWidgets('AppConfirmDialog.show returns null when cancelled', (
    tester,
  ) async {
    String? result = 'initial';
    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppConfirmDialog.show(
                context,
                title: 'سحب العرض',
                message: 'هل أنت متأكد من سحب العرض؟',
                confirmLabel: 'سحب',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
