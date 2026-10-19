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

  testWidgets('a floating list opens over the page without resizing it', (
    tester,
  ) async {
    String? chosen;
    await pumpComponent(
      tester,
      Column(
        children: [
          AppDropdown<String>(
            key: const Key('dropdown'),
            floating: true,
            hint: 'اختر المدينة',
            value: null,
            options: const [
              AppDropdownOption(value: 'madinah', title: 'المدينة المنورة'),
              AppDropdownOption(value: 'jeddah', title: 'جدة'),
            ],
            onChanged: (value) => chosen = value,
          ),
          const Text('تحت الحقل'),
        ],
      ),
    );
    final below = tester.getTopLeft(find.text('تحت الحقل'));

    await tester.tap(find.text('اختر المدينة'));
    await tester.pumpAndSettle();
    expect(find.text('جدة'), findsOneWidget);
    // The page below the field didn't move.
    expect(tester.getTopLeft(find.text('تحت الحقل')), below);

    await tester.tap(find.text('جدة'));
    await tester.pumpAndSettle();
    expect(chosen, 'jeddah');
    expect(find.text('المدينة المنورة'), findsNothing);
  });

  testWidgets('a tap outside closes the floating list', (tester) async {
    await pumpComponent(
      tester,
      Column(
        children: [
          AppDropdown<String>(
            floating: true,
            hint: 'اختر المدينة',
            value: null,
            options: const [AppDropdownOption(value: 'jeddah', title: 'جدة')],
            onChanged: (_) {},
          ),
          const SizedBox(height: 200),
          const Text('مكان آخر'),
        ],
      ),
    );

    await tester.tap(find.text('اختر المدينة'));
    await tester.pumpAndSettle();
    expect(find.text('جدة'), findsOneWidget);

    await tester.tap(find.text('مكان آخر'));
    await tester.pumpAndSettle();
    expect(find.text('جدة'), findsNothing);
  });
}
