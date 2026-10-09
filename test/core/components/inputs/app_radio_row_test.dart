import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows title and subtitle and reports taps', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppRadioRow(
        title: 'التمديدات الكهربائية',
        subtitle: 'رفض العميل التحديث',
        subtitleTone: AppTone.danger,
        selected: false,
        onTap: () => taps++,
      ),
    );

    expect(find.text('رفض العميل التحديث'), findsOneWidget);
    await tester.tap(find.text('التمديدات الكهربائية'));
    expect(taps, 1);
  });

  testWidgets('a selected row is light orange, or ink-bordered', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      Column(
        children: [
          AppRadioRow(title: 'مدى', selected: true, onTap: () {}),
          AppRadioRow(
            title: 'العمل غير مكتمل',
            selected: true,
            accent: AppRadioRowAccent.ink,
            onTap: () {},
          ),
        ],
      ),
    );

    Material materialOf(String title) => tester.widget<Material>(
      find
          .ancestor(of: find.text(title), matching: find.byType(Material))
          .first,
    );
    expect(materialOf('مدى').color, AppColors.primaryLight);
    expect(materialOf('العمل غير مكتمل').color, AppColors.surfaceMuted);
  });
}
