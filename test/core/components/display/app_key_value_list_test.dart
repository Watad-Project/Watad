import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';

import '../../../helpers/pump_component.dart';

void main() {
  const rows = [
    AppKeyValueRow(label: 'المستفيد', value: 'مؤسسة البناء المتين'),
    AppKeyValueRow(
      label: 'الآيبان',
      value: 'SA03 8000 0000 6080 1016 4471',
      copyValue: 'SA0380000000608010164471',
      isMonospace: true,
      isCopyable: true,
    ),
    AppKeyValueRow(label: 'المبلغ', value: '٧٢٬٠٠٠ ر.س'),
  ];

  testWidgets('shows every row, the IBAN left to right', (tester) async {
    await pumpComponent(
      tester,
      const AppKeyValueList(rows: rows, copyLabel: 'نسخ'),
    );

    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('٧٢٬٠٠٠ ر.س'), findsOneWidget);
    final iban = tester.widget<Text>(find.text(rows[1].value));
    expect(iban.textDirection, TextDirection.ltr);
    expect(iban.maxLines, 1);
    // Only the IBAN row can be copied.
    expect(find.text('نسخ'), findsOneWidget);
  });

  testWidgets('copies the copy value and reports it', (tester) async {
    final clipboard = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboard.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final copied = <String>[];
    await pumpComponent(
      tester,
      AppKeyValueList(rows: rows, copyLabel: 'نسخ', onCopied: copied.add),
    );

    await tester.tap(find.text('نسخ'));
    await tester.pump();
    expect(clipboard, [
      {'text': 'SA0380000000608010164471'},
    ]);
    expect(copied, ['SA0380000000608010164471']);
  });
}
