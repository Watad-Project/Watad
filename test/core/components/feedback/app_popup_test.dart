import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/theme/app_motion.dart';

import '../../../helpers/pump_component.dart';

void main() {
  Future<void> pumpOpener(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    await pumpLocalizedApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
  }

  testWidgets('a dialog fades in while it grows, then closes', (tester) async {
    await pumpOpener(
      tester,
      (context) => AppPopup.dialog<void>(
        context,
        builder: (_) => const Dialog(child: Text('dialog')),
      ),
    );

    await tester.pump();
    await tester.pump(AppMotion.enter ~/ 4);
    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.text('dialog'),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, inExclusiveRange(0.94, 1));

    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    // A tap outside closes it.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsNothing);
  });

  testWidgets('a sheet slides up and closes when dragged down', (tester) async {
    await pumpOpener(
      tester,
      (context) => AppPopup.sheet<void>(
        context,
        builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);

    await tester.drag(find.text('sheet'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
  });
}
