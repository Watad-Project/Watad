import 'package:flutter/material.dart';

/// Closes the keyboard the way people expect, everywhere in the app:
///
/// - a tap anywhere outside the text field (empty space, a card, a button);
/// - a drag on a list or a scrolling page.
///
/// Moving from one text field to another keeps the keyboard up: text fields
/// share one tap region, so that tap isn't "outside".
///
/// `WatadApp` puts it around every page, dialog and sheet once. Pages and
/// fields add nothing for this: no `GestureDetector` that unfocuses, no
/// `onTapOutside`, no `keyboardDismissBehavior` (APP_ARCHITECTURE.md §10).
class AppKeyboardDismiss extends StatelessWidget {
  const AppKeyboardDismiss({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        // What a text field does on a tap outside it. Flutter's default
        // keeps the keyboard up on phones.
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (intent) {
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        ),
        child: child,
      ),
    );
  }
}
