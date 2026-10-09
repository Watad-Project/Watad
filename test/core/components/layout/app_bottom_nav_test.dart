import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/theme/app_theme.dart';

void main() {
  testWidgets('shows the tabs it is given and reports taps', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTap: (i) => tapped = i,
            items: const [
              AppBottomNavItem(icon: Icons.home_outlined, label: 'الرئيسية'),
              AppBottomNavItem(icon: Icons.work_outline, label: 'مشاريعي'),
              AppBottomNavItem(icon: Icons.storefront_outlined, label: 'السوق'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('مشاريعي'), findsOneWidget);
    await tester.tap(find.text('السوق'));
    expect(tapped, 2);
  });
}
