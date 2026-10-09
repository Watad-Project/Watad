import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_theme.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, AppTopBar bar) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(appBar: bar),
        ),
      ),
    );
  }

  testWidgets('shows the title and goes back', (tester) async {
    var backs = 0;
    await pumpBar(
      tester,
      AppTopBar(title: 'فيلا سكنية — حي الياسمين', onBack: () => backs++),
    );

    expect(find.text('فيلا سكنية — حي الياسمين'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backs, 1);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('has no back arrow without onBack', (tester) async {
    await pumpBar(tester, const AppTopBar(title: 'الرئيسية'));

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
