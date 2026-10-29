import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  Finder chevron() => find.byIcon(Icons.chevron_right);

  testWidgets('shows the label, the line under it and the tag; a tap opens', (
    tester,
  ) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppMenuRow(
        icon: Icons.account_balance_outlined,
        label: 'الحساب البنكي',
        subtitle: 'يحوّل العملاء دفعاتهم إليه',
        tag: 'مطلوب',
        tagTone: AppTone.attention,
        onTap: () => taps++,
      ),
    );

    expect(find.text('الحساب البنكي'), findsOneWidget);
    expect(find.text('يحوّل العملاء دفعاتهم إليه'), findsOneWidget);
    expect(
      tester.widget<AppStatusBadge>(find.byType(AppStatusBadge)).tone,
      AppTone.attention,
    );
    expect(chevron(), findsOneWidget);

    await tester.tap(find.text('الحساب البنكي'));
    expect(taps, 1);
  });

  testWidgets('without onTap it only shows something: no chevron, no ripple', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppMenuRow(icon: Icons.verified_outlined, label: 'حالة التوثيق'),
    );

    expect(chevron(), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a muted row hides the chevron, but a tap still says why', (
    tester,
  ) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppMenuRow(
        icon: Icons.settings_outlined,
        label: 'الإعدادات',
        tag: 'قريبًا',
        isMuted: true,
        onTap: () => taps++,
      ),
    );

    expect(chevron(), findsNothing);
    expect(find.text('قريبًا'), findsOneWidget);
    await tester.tap(find.text('الإعدادات'));
    expect(taps, 1);
  });

  testWidgets('the chevron points to the end of the line', (tester) async {
    expect(Icons.chevron_right.matchTextDirection, isTrue);
  });

  testWidgets('fits large, bold text with a long label and tag', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      AppMenuRow(
        icon: Icons.storefront_outlined,
        label: 'إدارة المنتجات المعروضة في السوق وطلبات الشراء',
        subtitle: 'كل ما يخص البيع والشراء في مكان واحد',
        tag: 'قيد المراجعة من الإدارة',
        onTap: () {},
      ),
      textScale: largeTextScale,
      boldText: true,
    );

    expect(tester.takeException(), isNull);
  });
}
