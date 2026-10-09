import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the mark, the label and the hash', (tester) async {
    await pumpComponent(
      tester,
      const AppIconTag(
        label: 'موثّقة',
        icon: Icons.check,
        detail: '0x7f3a…c9d2',
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('موثّقة'), findsOneWidget);
    final hash = tester.widget<Text>(find.text('0x7f3a…c9d2'));
    expect(hash.textDirection, TextDirection.ltr);
  });

  testWidgets('colors the label with its tone', (tester) async {
    await pumpComponent(
      tester,
      const AppIconTag(
        label: 'بانتظار اعتماد العميل',
        icon: Icons.priority_high,
        tone: AppTone.attention,
      ),
    );

    final text = tester.widget<Text>(find.text('بانتظار اعتماد العميل'));
    expect(text.style?.color, AppTone.attention.foreground);
  });
}
