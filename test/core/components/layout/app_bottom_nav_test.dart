import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_bottom_nav.dart';
import 'package:watad/core/theme/app_theme.dart';

void main() {
  Future<void> pumpNav(
    WidgetTester tester, {
    int currentIndex = 0,
    ValueChanged<int>? onTap,
    List<AppBottomNavItem>? items,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
            items:
                items ??
                const [
                  AppBottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'الرئيسية',
                  ),
                  AppBottomNavItem(icon: Icons.work_outline, label: 'مشاريعي'),
                  AppBottomNavItem(
                    icon: Icons.storefront_outlined,
                    label: 'السوق',
                  ),
                ],
          ),
        ),
      ),
    );
  }

  testWidgets('shows the tabs it is given and reports taps', (tester) async {
    int? tapped;
    await pumpNav(tester, onTap: (i) => tapped = i);

    expect(find.text('مشاريعي'), findsOneWidget);
    await tester.tap(find.text('السوق'));
    expect(tapped, 2);
  });

  testWidgets('marks the selected tab, with its filled icon', (tester) async {
    await pumpNav(tester);

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('الرئيسية')),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('السوق')),
      isSemantics(isSelected: false, isButton: true),
    );
  });

  testWidgets('shows badge counts, 99+ above 99, and none for 0', (
    tester,
  ) async {
    await pumpNav(
      tester,
      items: const [
        AppBottomNavItem(
          icon: Icons.verified_user_outlined,
          label: 'التوثيق',
          badgeCount: 3,
        ),
        AppBottomNavItem(
          icon: Icons.flag_outlined,
          label: 'البلاغات',
          badgeCount: 150,
        ),
        AppBottomNavItem(
          icon: Icons.people_outline,
          label: 'المستخدمون',
          badgeCount: 0,
        ),
      ],
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.bySemanticsLabel('التوثيق, 3'), findsOneWidget);
  });
}
