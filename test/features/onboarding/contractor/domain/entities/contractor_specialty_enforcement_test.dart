import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/onboarding/contractor/domain/entities/contractor_specialty.dart';
import 'package:watad/features/onboarding/contractor/domain/entities/contractor_specialty_enforcement.dart';

void main() {
  group('ContractorSpecialtyEnforcement', () {
    test('canSendOffers returns false if contractor is not verified', () {
      final allowed = ContractorSpecialtyEnforcement.canSendOffers(
        isVerified: false,
        specializedField: 'مقاولات عامة',
      );

      expect(allowed, isFalse);
    });

    test('canSendOffers returns false if specialty is null or empty', () {
      expect(
        ContractorSpecialtyEnforcement.canSendOffers(
          isVerified: true,
          specializedField: null,
        ),
        isFalse,
      );

      expect(
        ContractorSpecialtyEnforcement.canSendOffers(
          isVerified: true,
          specializedField: '',
        ),
        isFalse,
      );
    });

    test('canSendOffers returns true when verified and has specialty', () {
      final allowed = ContractorSpecialtyEnforcement.canSendOffers(
        isVerified: true,
        specializedField: 'تشطيبات',
      );

      expect(allowed, isTrue);
    });

    test('ensureCanSendOffers returns PermissionFailure when unverified', () {
      final result = ContractorSpecialtyEnforcement.ensureCanSendOffers(
        isVerified: false,
        specializedField: 'مقاولات عامة',
      );

      expect(result, isA<Failed<void>>());
      final failed = result as Failed<void>;
      expect(failed.failure, isA<PermissionFailure>());
    });

    test(
      'ensureCanSendOffers returns ValidationFailure when specialty missing',
      () {
        final result = ContractorSpecialtyEnforcement.ensureCanSendOffers(
          isVerified: true,
          specializedField: null,
        );

        expect(result, isA<Failed<void>>());
        final failed = result as Failed<void>;
        expect(failed.failure, isA<ValidationFailure>());
        expect(failed.failure.messageKey, 'onboarding.specialty_required');
      },
    );

    test(
      'ensureCanSendOffers returns Success when verified with specialty',
      () {
        final result = ContractorSpecialtyEnforcement.ensureCanSendOffers(
          isVerified: true,
          specializedField: 'عزل',
        );

        expect(result, isA<Success<void>>());
      },
    );
  });

  group('ContractorSpecialty', () {
    test('availableKeys contains the 5 expected specialty keys', () {
      expect(ContractorSpecialty.availableKeys, [
        'onboarding.specialty_general_contracting',
        'onboarding.specialty_finishes',
        'onboarding.specialty_electrical_plumbing',
        'onboarding.specialty_renovation',
        'onboarding.specialty_insulation',
      ]);
    });
  });
}
