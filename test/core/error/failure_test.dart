import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/localization/app_localization.dart';

import '../../helpers/pump_component.dart';

void main() {
  const failures = <Failure>[
    NetworkFailure(),
    AuthFailure(),
    PermissionFailure(),
    NotFoundFailure(),
    ConflictFailure(),
    RateLimitFailure(),
    ValidationFailure('validation.invalid'),
    ServerFailure(),
    UnknownFailure(),
  ];

  for (final locale in AppLocalization.supportedLocales) {
    test('every failure has its message in ${locale.languageCode}', () async {
      final translations = await const TestAssetLoader().load(
        AppLocalization.path,
        locale,
      );

      for (final failure in failures) {
        expect(
          _lookUp(translations, failure.messageKey),
          isA<String>(),
          reason: '${failure.messageKey} in ${locale.languageCode}',
        );
      }
    });
  }

  test('keeps the error behind the failure', () {
    final error = Exception('offline');

    expect(NetworkFailure(error).cause, same(error));
  });
}

/// The value at [key] (`errors.network`) in the nested [translations].
Object? _lookUp(Map<String, dynamic> translations, String key) {
  Object? value = translations;
  for (final part in key.split('.')) {
    value = value is Map<String, dynamic> ? value[part] : null;
  }
  return value;
}
