import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Loads one language from the translation files in `assets/translations/`,
/// one file per group and language: `common.ar.json`, `auth.en.json`, …
///
/// Each feature owns its pair of files and writes its keys without the
/// feature's name. This loader puts every file under its group, so
/// `{"login_title": "…"}` in `auth.ar.json` is read with
/// `context.tr('auth.login_title')`.
///
/// A new file needs no `pubspec.yaml` change: the loader finds it through
/// the asset manifest, and `assets/translations/` is already registered.
class AppTranslationsLoader extends AssetLoader {
  const AppTranslationsLoader();

  static final RegExp _fileName = RegExp(
    r'^([a-z][a-z0-9_]*)\.([a-z]{2})\.json$',
  );

  /// The group of a file named `<group>.<language>.json` in [languageCode]:
  /// `auth` for `auth.ar.json` in Arabic. Null for any other file.
  static String? groupOf(String fileName, String languageCode) {
    final match = _fileName.firstMatch(fileName);
    if (match == null || match.group(2) != languageCode) return null;
    return match.group(1);
  }

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final translations = <String, dynamic>{};
    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith('$path/')) continue;
      final group = groupOf(
        asset.substring(path.length + 1),
        locale.languageCode,
      );
      if (group == null) continue;
      translations[group] = jsonDecode(await rootBundle.loadString(asset));
    }
    return translations;
  }
}
