import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_specialty.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_specialty_text.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  /// Runs [check] with a context in [locale], the real translations loaded.
  Future<void> inLocale(
    WidgetTester tester,
    Locale locale,
    void Function(BuildContext context) check,
  ) async {
    late BuildContext captured;
    await pumpLocalizedApp(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
      locale: locale,
    );
    check(captured);
  }

  testWidgets('a specialty saved in Arabic reads in English', (tester) async {
    await inLocale(tester, AppLocalization.english, (context) {
      expect(
        ProfileSpecialtyText.of(context, 'مقاولات عامة'),
        'General Contracting',
      );
      expect(
        ProfileSpecialtyText.choiceOf(context, 'كهرباء وسباكة'),
        ProfileSpecialty.electricalPlumbing,
      );
    });
  });

  testWidgets('a specialty saved in English reads in Arabic', (tester) async {
    await inLocale(tester, AppLocalization.arabic, (context) {
      expect(ProfileSpecialtyText.of(context, 'Restoration'), 'ترميم');
      expect(
        ProfileSpecialtyText.choiceOf(context, 'Finishes'),
        ProfileSpecialty.finishes,
      );
    });
  });

  testWidgets('unset or unknown specialties', (tester) async {
    await inLocale(tester, AppLocalization.arabic, (context) {
      expect(ProfileSpecialtyText.of(context, 'contractor'), isNull);
      expect(ProfileSpecialtyText.of(context, ''), isNull);
      // Not a choice: shown as stored, so nothing is hidden.
      expect(ProfileSpecialtyText.of(context, 'fdfds'), 'fdfds');
      expect(ProfileSpecialtyText.choiceOf(context, 'fdfds'), isNull);
    });
  });
}
