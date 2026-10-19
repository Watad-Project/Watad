import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/localization/app_localization.dart';

import '../../helpers/pump_component.dart';

void main() {
  /// Every translation of [locale], grouped as the app reads them.
  Future<Map<String, dynamic>> load(Locale locale) =>
      const TestAssetLoader().load(AppLocalization.path, locale);

  bool hasKey(Map<String, dynamic> json, String key) {
    Object? node = json;
    for (final part in key.split('.')) {
      if (node is! Map<String, dynamic> || !node.containsKey(part)) {
        return false;
      }
      node = node[part];
    }
    return node is String;
  }

  test('every supported locale has the common translations', () async {
    for (final locale in AppLocalization.supportedLocales) {
      final translations = await load(locale);
      expect(
        translations['common'],
        isA<Map<String, dynamic>>(),
        reason: 'common.${locale.languageCode}.json is missing',
      );
    }
  });

  // A key that is missing shows up on screen as "common.something".
  test('every key the code translates exists in every language', () async {
    final keyInCode = RegExp(r"""\btr\(\s*'([a-z0-9_.]+)'""");
    final keys = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        // Examples in doc comments name keys that don't exist yet.
        final code = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        for (final match in keyInCode.allMatches(code)) {
          keys.add(match.group(1)!);
        }
      }
    }
    expect(keys, isNotEmpty);

    for (final locale in AppLocalization.supportedLocales) {
      final translations = await load(locale);
      final missing = keys.where((key) => !hasKey(translations, key)).toList();
      expect(
        missing,
        isEmpty,
        reason: 'missing in the ${locale.languageCode} files',
      );
    }
  });

  testWidgets('toggleLanguage switches Arabic and English, and the direction', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: context.toggleLanguage,
          child: Text(context.isArabic ? 'ar' : 'en'),
        ),
      ),
    );

    expect(find.text('ar'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('ar'))),
      TextDirection.rtl,
    );

    await tester.tap(find.text('ar'));
    await tester.pumpAndSettle();
    expect(find.text('en'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('en'))),
      TextDirection.ltr,
    );

    await tester.tap(find.text('en'));
    await tester.pumpAndSettle();
    expect(find.text('ar'), findsOneWidget);
  });

  /// The context of a widget shown in [locale].
  Future<BuildContext> contextIn(WidgetTester tester, Locale locale) async {
    late BuildContext captured;
    await pumpComponent(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
      locale: locale,
    );
    return captured;
  }

  testWidgets('formatNumber writes Arabic-Indic digits in Arabic', (
    tester,
  ) async {
    final context = await contextIn(tester, AppLocalization.arabic);
    expect(context.formatNumber(465000), '٤٦٥٬٠٠٠');
    expect(context.formatNumber(4.75, decimals: 1), '٤٫٨');
  });

  testWidgets('formatNumber writes Western digits in English', (tester) async {
    final context = await contextIn(tester, AppLocalization.english);
    expect(context.formatNumber(465000), '465,000');
    expect(context.formatNumber(4.75, decimals: 1), '4.8');
  });

  testWidgets('Arabic plurals use all six forms', (tester) async {
    final context = await contextIn(tester, AppLocalization.arabic);
    String ratings(int n) => context.plural(
      'home.ratings_count',
      n,
      args: [context.formatNumber(n)],
    );
    expect(ratings(3), '٣ تقييمات');
    expect(ratings(64), '٦٤ تقييمًا');
    expect(ratings(100), '١٠٠ تقييم');
  });
}
