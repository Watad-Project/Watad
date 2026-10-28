import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_check.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_draft.dart';

/// Checks the bank details form by the rules the database applies before it
/// saves (`private.contractor_bank_details_prepare`, migration 78), so each
/// field can say what's wrong before anything is sent (GRA-64). The
/// database only answers `22023`, without saying which field.
///
/// - Both names are trimmed. The beneficiary has 2 to 150 characters, the
///   bank 2 to 100.
/// - The IBAN is cleaned the database's way: Arabic-Indic (٠-٩) and Persian
///   (۰-۹) digits become 0-9, spaces and dashes go, and letters are
///   upper-cased. Then it must be `SA`, 4 digits and 18 digits or letters,
///   with check digits that add up (ISO 13616, mod 97).
///
/// It always succeeds: what's wrong is in the [ContractorBankDetailsCheck].
class ContractorCheckBankDetailsUseCase
    implements UseCase<ContractorBankDetailsCheck, ContractorBankDetailsDraft> {
  const ContractorCheckBankDetailsUseCase();

  /// `SA`, the 2 check digits, the 2-digit bank code and the 18-character
  /// account number: the shape `contractor_bank_details.iban` accepts.
  static final RegExp _ibanShape = RegExp(r'^SA[0-9]{4}[0-9A-Z]{18}$');

  @override
  Future<Result<ContractorBankDetailsCheck>> call(
    ContractorBankDetailsDraft params,
  ) async {
    final beneficiaryName = params.beneficiaryName.trim();
    final bankName = params.bankName.trim();
    final iban = _cleanIban(params.iban);
    return Success(
      ContractorBankDetailsCheck(
        details: ContractorBankDetails(
          beneficiaryName: beneficiaryName,
          bankName: bankName,
          iban: iban,
        ),
        beneficiaryNameError: _hasLength(beneficiaryName, 2, 150)
            ? null
            : 'validation.beneficiary_name_invalid',
        bankNameError: _hasLength(bankName, 2, 100)
            ? null
            : 'validation.bank_name_invalid',
        ibanError: _ibanError(iban),
      ),
    );
  }

  /// Counted in characters, like Postgres' `char_length`, not in UTF-16
  /// units.
  static bool _hasLength(String text, int min, int max) {
    final length = text.runes.length;
    return length >= min && length <= max;
  }

  static String? _ibanError(String iban) {
    if (iban.isEmpty) return 'validation.iban_required';
    if (!_ibanShape.hasMatch(iban)) return 'validation.iban_invalid';
    if (!_hasValidCheckDigits(iban)) return 'validation.iban_checksum';
    return null;
  }

  /// [raw] as the database keeps it: Latin digits, no spaces or dashes,
  /// upper case.
  static String _cleanIban(String raw) => String.fromCharCodes([
    for (final rune in raw.runes) _latinDigit(rune) ?? rune,
  ]).replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  /// The Latin digit for an Arabic-Indic (U+0660 to U+0669) or a Persian
  /// (U+06F0 to U+06F9) one, else null. By code point, because the
  /// architecture check refuses Arabic characters in code.
  static int? _latinDigit(int rune) {
    for (final zero in const [0x0660, 0x06F0]) {
      if (rune >= zero && rune <= zero + 9) return 0x30 + rune - zero;
    }
    return null;
  }

  /// ISO 13616: the first 4 characters move to the end, letters read as
  /// numbers (A = 10 … Z = 35), and that number divided by 97 leaves 1. It
  /// has about 30 digits, so the remainder is worked out one character at a
  /// time, as in the database.
  static bool _hasValidCheckDigits(String iban) {
    var remainder = 0;
    for (final unit in (iban.substring(4) + iban.substring(0, 4)).codeUnits) {
      remainder = unit <= 0x39
          ? (remainder * 10 + unit - 0x30) % 97
          : (remainder * 100 + unit - 0x37) % 97;
    }
    return remainder == 1;
  }
}
