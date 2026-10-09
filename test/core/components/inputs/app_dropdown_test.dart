import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  const options = [
    AppDropdownOption(
      value: 'build',
      title: 'تأسيس منزل',
      subtitle: 'يتطلب صك الملكية',
      subtitleTone: AppTone.attention,
      tag: 'يتطلب صك',
    ),
    AppDropdownOption(
      value: 'repair',
      title: 'إصلاحات داخل المنزل',
      subtitle: 'لا يلزم صك',
      subtitleTone: AppTone.success,
    ),
  ];

  testWidgets('shows the hint until something is chosen', (tester) async {
    await pumpComponent(
      tester,
      AppDropdown<String>(
        options: options,
        value: null,
        hint: 'اختر نوع المشروع',
        onChanged: (_) {},
      ),
    );

    expect(find.text('اختر نوع المشروع'), findsOneWidget);
    expect(find.text('لا يلزم صك'), findsNothing);
  });

  testWidgets('opens the list, reports the choice and closes', (tester) async {
    String? chosen;
    await pumpComponent(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AppDropdown<String>(
          label: 'نوع المشروع',
          options: options,
          value: chosen,
          onChanged: (value) => setState(() => chosen = value),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.text('لا يلزم صك'), findsOneWidget);

    await tester.tap(find.text('تأسيس منزل'));
    await tester.pumpAndSettle();
    expect(chosen, 'build');
    expect(find.text('لا يلزم صك'), findsNothing);
    // The closed field shows the choice and its tag.
    expect(find.text('تأسيس منزل'), findsOneWidget);
    expect(find.widgetWithText(AppStatusBadge, 'يتطلب صك'), findsOneWidget);
  });

  testWidgets('does not open when disabled', (tester) async {
    await pumpComponent(
      tester,
      const AppDropdown<String>(options: options, value: null, onChanged: null),
    );

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.text('لا يلزم صك'), findsNothing);
  });
}
