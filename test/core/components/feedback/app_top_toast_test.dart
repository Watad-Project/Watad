import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_top_toast.dart';

import '../../../helpers/pump_component.dart';

void main() {
  /// A button that shows a toast, with [onTap] as its tap.
  Widget trigger({VoidCallback? onTap, String title = 'عرض جديد'}) => Builder(
    builder: (context) => TextButton(
      onPressed: () => AppTopToast.show(
        context,
        title: title,
        message: 'وصلك عرض على مشروعك',
        onTap: onTap,
      ),
      child: const Text('show'),
    ),
  );

  testWidgets('slides in at the top, then leaves by itself', (tester) async {
    await pumpComponent(tester, trigger());

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('عرض جديد'), findsOneWidget);
    expect(find.text('وصلك عرض على مشروعك'), findsOneWidget);
    // Near the top of the screen.
    expect(tester.getTopLeft(find.byType(AppTopToast)).dy, lessThan(100));

    await tester.pump(AppTopToast.defaultDuration);
    await tester.pumpAndSettle();
    expect(find.byType(AppTopToast), findsNothing);
  });

  testWidgets('a tap opens it and closes it', (tester) async {
    var taps = 0;
    await pumpComponent(tester, trigger(onTap: () => taps++));

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض جديد'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.byType(AppTopToast), findsNothing);
  });

  testWidgets('a swipe up closes it', (tester) async {
    await pumpComponent(tester, trigger());

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.fling(find.text('عرض جديد'), const Offset(0, -200), 1000);
    await tester.pumpAndSettle();

    expect(find.byType(AppTopToast), findsNothing);
  });

  testWidgets('a new one replaces the one showing', (tester) async {
    await pumpComponent(
      tester,
      Column(
        children: [
          trigger(),
          Builder(
            builder: (context) => TextButton(
              onPressed: () => AppTopToast.show(context, title: 'مهمة جديدة'),
              child: const Text('second'),
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();

    expect(find.text('عرض جديد'), findsNothing);
    expect(find.text('مهمة جديدة'), findsOneWidget);
    await tester.pump(AppTopToast.defaultDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('fits large, bold text', (tester) async {
    await pumpComponent(
      tester,
      trigger(title: 'تم توثيق صك الملكية ونُشر مشروعك للمقاولين'),
      textScale: largeTextScale,
      boldText: true,
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pump(AppTopToast.defaultDuration);
    await tester.pumpAndSettle();
  });
}
