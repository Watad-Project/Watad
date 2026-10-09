import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/localization/app_localization.dart';

void main() {
  Map<String, dynamic> load(String languageCode) => jsonDecode(
    File('${AppLocalization.path}/$languageCode.json').readAsStringSync(),
  ) as Map<String, dynamic>;

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

  test('every supported locale has a translation file', () {
    for (final locale in AppLocalization.supportedLocales) {
      expect(
        File('${AppLocalization.path}/${locale.languageCode}.json')
            .existsSync(),
        isTrue,
        reason: '${locale.languageCode}.json is missing',
      );
    }
  });

  // A key that is missing shows up on screen as "common.something".
  test('every key the code translates exists in every language', () {
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
      final json = load(locale.languageCode);
      final missing = keys.where((key) => !hasKey(json, key)).toList();
      expect(
        missing,
        isEmpty,
        reason: 'missing in ${locale.languageCode}.json',
      );
    }
  });
}
