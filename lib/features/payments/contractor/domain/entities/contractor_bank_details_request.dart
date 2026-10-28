import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_check.dart';

/// «حفظ» on the bank details screen (GRA-64): the checked form, and the
/// details saved before. Null the first time, so they're added; otherwise
/// they're changed.
class ContractorBankDetailsRequest {
  const ContractorBankDetailsRequest({required this.check, this.saved});

  final ContractorBankDetailsCheck check;
  final ContractorBankDetails? saved;
}
