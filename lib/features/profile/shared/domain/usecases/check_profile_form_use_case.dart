import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_draft.dart';

/// Checks the text fields of the edit profile form by the database's rules
/// (GRA-60), so each field can say what's wrong before anything is sent.
///
/// - The name is trimmed and has 2 to 100 characters. The database allows
///   up to 100; the 2 is the app's own minimum.
/// - The company name is trimmed and has 2 to 150 characters (migration
///   02).
/// - The CR number is cleaned: Arabic-Indic (٠-٩) and Persian (۰-۹) digits
///   become 0-9 and spaces go. Then it must be exactly 10 digits.
///
/// It always succeeds: what's wrong is in the [ProfileFormCheck].
class CheckProfileFormUseCase
    implements UseCase<ProfileFormCheck, ProfileFormDraft> {
  const CheckProfileFormUseCase();

  static final RegExp _crShape = RegExp(r'^[0-9]{10}$');

  @override
  Future<Result<ProfileFormCheck>> call(ProfileFormDraft params) async {
    final fullName = params.fullName.trim();
    final companyName = params.companyName?.trim();
    final crNumber = switch (params.crNumber) {
      final raw? => _cleanCrNumber(raw),
      null => null,
    };
    return Success(
      ProfileFormCheck(
        fullName: fullName,
        companyName: companyName,
        crNumber: crNumber,
        fullNameError: _hasLength(fullName, 2, 100)
            ? null
            : 'profile.edit.name_invalid',
        companyNameError: companyName == null || _hasLength(companyName, 2, 150)
            ? null
            : 'profile.edit.company_name_invalid',
        crNumberError: crNumber == null || _crShape.hasMatch(crNumber)
            ? null
            : 'profile.edit.cr_number_invalid',
      ),
    );
  }

  /// Counted in characters, like Postgres' `char_length`, not in UTF-16
  /// units.
  static bool _hasLength(String text, int min, int max) {
    final length = text.runes.length;
    return length >= min && length <= max;
  }

  /// [raw] with Latin digits and no spaces.
  static String _cleanCrNumber(String raw) => String.fromCharCodes([
    for (final rune in raw.runes) _latinDigit(rune) ?? rune,
  ]).replaceAll(RegExp(r'\s'), '');

  /// The Latin digit for an Arabic-Indic (U+0660 to U+0669) or a Persian
  /// (U+06F0 to U+06F9) one, else null. By code point, because the
  /// architecture check refuses Arabic characters in code.
  static int? _latinDigit(int rune) {
    for (final zero in const [0x0660, 0x06F0]) {
      if (rune >= zero && rune <= zero + 9) return 0x30 + rune - zero;
    }
    return null;
  }
}
