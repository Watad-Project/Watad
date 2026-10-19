import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_keyboard_dismiss.dart';

import '../../../helpers/pump_component.dart';

void main() {
  final first = FocusNode();
  final second = FocusNode();
  var presses = 0;

  tearDownAll(() {
    first.dispose();
    second.dispose();
  });

  Future<void> pumpForm(WidgetTester tester) async {
    presses = 0;
    await pumpLocalizedApp(
      tester,
      AppKeyboardDismiss(
        child: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(key: const Key('first'), focusNode: first),
              TextField(key: const Key('second'), focusNode: second),
              TextButton(onPressed: () => presses++, child: const Text('send')),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    expect(first.hasFocus, isTrue);
  }

  testWidgets('a tap on empty space closes the keyboard', (tester) async {
    await pumpForm(tester);

    await tester.tapAt(const Offset(400, 500));
    await tester.pump();
    expect(first.hasFocus, isFalse);
  });

  testWidgets('a tap on a button closes it and still presses the button', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('send'));
    await tester.pump();
    expect(first.hasFocus, isFalse);
    expect(presses, 1);
  });

  testWidgets('moving to another field keeps it up', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.byKey(const Key('second')));
    await tester.pump();
    expect(second.hasFocus, isTrue);
  });

  testWidgets('a drag on the list closes it', (tester) async {
    await pumpForm(tester);

    await tester.drag(find.text('send'), const Offset(0, -200));
    await tester.pump();
    expect(first.hasFocus, isFalse);
    expect(second.hasFocus, isFalse);
  });
}
