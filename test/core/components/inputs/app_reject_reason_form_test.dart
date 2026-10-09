import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_reject_reason_form.dart';

import '../../../helpers/pump_component.dart';

void main() {
  Future<List<(int, String)>> pumpForm(WidgetTester tester) async {
    final submitted = <(int, String)>[];
    await pumpComponent(
      tester,
      AppRejectReasonForm(
        reasons: const ['الأدلة غير كافية', 'العمل غير مكتمل'],
        onSubmit: (reason, details) => submitted.add((reason, details)),
      ),
    );
    return submitted;
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('uses the translated title, labels and button', (tester) async {
    await pumpForm(tester);

    for (final text in [
      'سبب الرفض',
      'التفاصيل',
      'إلزامي',
      'اكتب السبب...',
      'إرسال الرفض',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('the send button waits for a reason', (tester) async {
    await pumpForm(tester);

    expect(submitButton(tester).onPressed, isNull);
    await tester.tap(find.text('العمل غير مكتمل'));
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('asks for details before sending', (tester) async {
    final submitted = await pumpForm(tester);

    await tester.tap(find.text('العمل غير مكتمل'));
    await tester.pump();
    await tester.tap(find.text('إرسال الرفض'));
    await tester.pump();
    expect(find.text('السبب مطلوب قبل الإرسال'), findsOneWidget);
    expect(submitted, isEmpty);

    await tester.enterText(find.byType(TextFormField), '  لا تظهر الزوايا  ');
    await tester.pump();
    expect(find.text('السبب مطلوب قبل الإرسال'), findsNothing);
    await tester.tap(find.text('إرسال الرفض'));
    expect(submitted, [(1, 'لا تظهر الزوايا')]);
  });
}
