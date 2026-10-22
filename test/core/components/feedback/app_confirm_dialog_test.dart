import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';

import '../../../helpers/pump_component.dart';

void main() {
  /// Opens the dialog from a button and keeps what it returns.
  Future<List<String?>> open(WidgetTester tester, {String? reasonLabel}) async {
    final results = <String?>[];
    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await AppConfirmDialog.show(
                context,
                title: 'إيقاف المستخدم؟',
                message: 'سيرى المستخدم السبب.',
                confirmLabel: 'إيقاف',
                reasonLabel: reasonLabel,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('confirming without a reason field returns an empty reason', (
    tester,
  ) async {
    final results = await open(tester);

    expect(find.text('إيقاف المستخدم؟'), findsOneWidget);
    expect(find.text('سيرى المستخدم السبب.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('إيقاف'));
    await tester.pumpAndSettle();
    expect(results, ['']);
  });

  testWidgets('a required reason must be written before confirming', (
    tester,
  ) async {
    final results = await open(tester, reasonLabel: 'السبب');

    await tester.tap(find.text('إيقاف'));
    await tester.pump();
    expect(find.text('السبب مطلوب قبل الإرسال'), findsOneWidget);
    expect(results, isEmpty);

    await tester.enterText(find.byType(TextField), '  رسائل مسيئة ');
    await tester.tap(find.text('إيقاف'));
    await tester.pumpAndSettle();
    expect(results, ['رسائل مسيئة']);
  });

  testWidgets('cancelling returns null', (tester) async {
    final results = await open(tester, reasonLabel: 'السبب');

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsNothing);
    expect(results, [null]);
  });
}
