import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/theme/app_colors.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('calls onPressed when tapped', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppButton(label: 'إرسال', onPressed: () => taps++),
    );

    await tester.tap(find.text('إرسال'));
    expect(taps, 1);
  });

  testWidgets('fills the width, except the link variant', (tester) async {
    await pumpComponent(
      tester,
      Column(
        children: [
          AppButton(label: 'primary', onPressed: () {}),
          AppButton(
            label: 'link',
            onPressed: () {},
            variant: AppButtonVariant.link,
          ),
        ],
      ),
    );

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    expect(tester.getSize(find.byType(FilledButton)).width, screenWidth - 32);
    expect(
      tester.getSize(find.byType(TextButton)).width,
      lessThan(screenWidth / 2),
    );
  });

  testWidgets('shows a spinner and ignores taps while loading', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppButton(label: 'إرسال', onPressed: () => taps++, isLoading: true),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('إرسال'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('the dark variant is ink', (tester) async {
    await pumpComponent(
      tester,
      AppButton(label: 'رفض', onPressed: () {}, variant: AppButtonVariant.dark),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.ink);
  });

  testWidgets('the secondary variant is an outlined button', (tester) async {
    await pumpComponent(
      tester,
      AppButton(
        label: 'حفظ',
        onPressed: () {},
        variant: AppButtonVariant.secondary,
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
