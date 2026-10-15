import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';

/// Domain rules enforcing that a contractor selects a specialty before they
/// are permitted to submit offers on projects.
abstract final class ContractorSpecialtyEnforcement {
  /// Whether the contractor satisfies the conditions to submit project offers.
  static bool canSendOffers({
    required bool isVerified,
    required String? specializedField,
  }) {
    if (!isVerified) return false;
    if (specializedField == null || specializedField.trim().isEmpty) {
      return false;
    }
    return true;
  }

  /// Validates that the contractor has a specialty selected and is verified,
  /// returning a [Failed] with appropriate [Failure] if not.
  static Result<void> ensureCanSendOffers({
    required bool isVerified,
    required String? specializedField,
  }) {
    if (!isVerified) {
      return const Failed(PermissionFailure());
    }
    if (specializedField == null || specializedField.trim().isEmpty) {
      return const Failed(ValidationFailure('onboarding.specialty_required'));
    }
    return const Success(null);
  }
}
