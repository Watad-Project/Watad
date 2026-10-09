import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';

import '../../../helpers/pump_component.dart';

void main() {
  /// Pumps an empty Arabic screen and returns a context under its Scaffold.
  Future<BuildContext> pumpScreen(WidgetTester tester) async {
    late BuildContext screen;
    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) {
            screen = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    return screen;
  }

  testWidgets('shows a plain message without an icon', (tester) async {
    final context = await pumpScreen(tester);

    context.showSnackBar('تم نسخ الآيبان');
    await tester.pumpAndSettle();

    expect(find.text('تم نسخ الآيبان'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('marks good news with a check', (tester) async {
    final context = await pumpScreen(tester);

    context.showSuccessSnackBar('تم حفظ العنوان');
    await tester.pumpAndSettle();

    expect(find.text('تم حفظ العنوان'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('adds a translated retry button to an error, kept 6 s', (
    tester,
  ) async {
    final context = await pumpScreen(tester);
    var retries = 0;

    context.showErrorSnackBar(
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.',
      onRetry: () => retries++,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, const Duration(seconds: 6));
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
  });

  testWidgets('an error without onRetry has no button', (tester) async {
    final context = await pumpScreen(tester);

    context.showErrorSnackBar('رقم السجل التجاري غير صحيح.');
    await tester.pumpAndSettle();

    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('a new snack bar replaces the one on screen', (tester) async {
    final context = await pumpScreen(tester);

    context.showSnackBar('الأول');
    await tester.pumpAndSettle();
    context.showSnackBar('الثاني');
    await tester.pumpAndSettle();

    expect(find.text('الأول'), findsNothing);
    expect(find.text('الثاني'), findsOneWidget);
  });

  testWidgets('hideSnackBar removes it', (tester) async {
    final context = await pumpScreen(tester);

    context.showSnackBar('تم الحفظ');
    await tester.pumpAndSettle();
    context.hideSnackBar();
    await tester.pumpAndSettle();

    expect(find.text('تم الحفظ'), findsNothing);
  });
}
