import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the label, the helper and the typed text', (tester) async {
    final changes = <String>[];
    await pumpComponent(
      tester,
      AppTextField(
        label: 'اسم المنشأة',
        helperText: '١٠ أرقام',
        onChanged: changes.add,
      ),
    );

    expect(find.text('اسم المنشأة'), findsOneWidget);
    expect(find.text('١٠ أرقام'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'مؤسسة البناء');
    expect(changes.last, 'مؤسسة البناء');
  });

  testWidgets('reports the keyboard action with the text', (tester) async {
    String? submitted;
    await pumpComponent(
      tester,
      AppTextField(onSubmitted: (value) => submitted = value),
    );

    await tester.enterText(find.byType(TextFormField), 'user@watad.sa');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'user@watad.sa');
  });

  testWidgets('shows the error text', (tester) async {
    await pumpComponent(
      tester,
      const AppTextField(errorText: 'السبب مطلوب قبل الإرسال'),
    );

    expect(find.text('السبب مطلوب قبل الإرسال'), findsOneWidget);
  });

  testWidgets('runs the validator inside a Form', (tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpComponent(
      tester,
      Form(
        key: formKey,
        child: AppTextField(
          validator: (value) => (value ?? '').isEmpty ? 'مطلوب' : null,
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('مطلوب'), findsOneWidget);
  });

  testWidgets('types monospace values left to right in Arabic', (tester) async {
    await pumpComponent(tester, const AppTextField(isMonospace: true));

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.textDirection, TextDirection.ltr);
    expect(editable.textAlign, TextAlign.end);
  });
}
