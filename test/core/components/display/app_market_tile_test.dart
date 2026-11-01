import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_market_tile.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the product and reports tap and add', (tester) async {
    var taps = 0;
    var adds = 0;
    await pumpComponent(
      tester,
      SizedBox(
        width: 180,
        child: AppMarketTile(
          title: 'حديد تسليح ١٢ مم',
          seller: 'مصنع الرياض للحديد',
          priceLabel: '٢٬٧٥٠ ر.س',
          unitLabel: '/ طن',
          conditionLabel: 'جديد',
          conditionTone: AppTone.success,
          onTap: () => taps++,
          onAdd: () => adds++,
        ),
      ),
    );

    for (final text in ['مصنع الرياض للحديد', '٢٬٧٥٠ ر.س', '/ طن', 'جديد']) {
      expect(find.text(text), findsOneWidget);
    }
    await tester.tap(find.byTooltip('إضافة'));
    await tester.tap(find.text('حديد تسليح ١٢ مم'));
    expect(adds, 1);
    expect(taps, 1);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('shows verified seller, rating and hides add button when asked', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const SizedBox(
        width: 180,
        child: AppMarketTile(
          title: 'أسمنت بورتلاندي',
          seller: 'شركة اليمامة',
          sellerIsVerified: true,
          ratingLabel: '٤٫٨ (١٢ تقييمًا)',
          priceLabel: '٢٥ ر.س',
          conditionLabel: 'نفد',
          conditionTone: AppTone.danger,
          showAddButton: false,
        ),
      ),
    );

    expect(find.byType(AppVerifiedName), findsOneWidget);
    expect(find.text('٤٫٨ (١٢ تقييمًا)'), findsOneWidget);
    expect(find.text('نفد'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
