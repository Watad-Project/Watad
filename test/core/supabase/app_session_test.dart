import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_onboarding_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/supabase/app_session.dart';

void main() {
  group('AppRole.fromProfile reads a v_my_profile row', () {
    test('staff are admins, even with a business', () {
      expect(
        AppRole.fromProfile(const {'is_admin': true, 'is_business': true}),
        AppRole.admin,
      );
    });

    test('a user with a business is a contractor', () {
      expect(
        AppRole.fromProfile(const {'is_admin': false, 'is_business': true}),
        AppRole.contractor,
      );
    });

    test('everyone else is a client, also without a row', () {
      expect(
        AppRole.fromProfile(const {'is_admin': false, 'is_business': false}),
        AppRole.client,
      );
      expect(
        AppRole.fromProfile(const {'is_admin': null, 'is_business': null}),
        AppRole.client,
      );
      expect(AppRole.fromProfile(const {}), AppRole.client);
    });
  });

  group('SupabaseAppSession.resolveContractorDestination', () {
    test('routes to signUpBusinessPath if isBusiness is false', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: false,
        business: null,
      );
      expect(dest, AuthRoutes.signUpBusinessPath);
    });

    test('routes to signUpBusinessPath if business row is null', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: true,
        business: null,
      );
      expect(dest, AuthRoutes.signUpBusinessPath);
    });

    test('routes to licensePath if status is unverified', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: true,
        business: const {'verification_status': 'unverified'},
      );
      expect(dest, ContractorKycRoutes.licensePath);
    });

    test(
      'routes to statusPath if status is pending (even if specialty is empty)',
      () {
        final dest = SupabaseAppSession.resolveContractorDestination(
          isBusiness: true,
          business: const {
            'verification_status': 'pending',
            'specialized_field': null,
          },
        );
        expect(dest, KycRoutes.statusPath);
      },
    );

    test('routes to statusPath if status is rejected', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: true,
        business: const {
          'verification_status': 'rejected',
          'specialized_field': null,
        },
      );
      expect(dest, KycRoutes.statusPath);
    });

    test('routes to specialtyPath if verified but specialty is null', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: true,
        business: const {
          'verification_status': 'verified',
          'specialized_field': null,
        },
      );
      expect(dest, ContractorOnboardingRoutes.specialtyPath);
    });

    test(
      'routes to specialtyPath if verified but specialty is empty string',
      () {
        final dest = SupabaseAppSession.resolveContractorDestination(
          isBusiness: true,
          business: const {
            'verification_status': 'verified',
            'specialized_field': '   ',
          },
        );
        expect(dest, ContractorOnboardingRoutes.specialtyPath);
      },
    );

    test('routes to specialtyPath if verified but specialty is default contractor string', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: true,
        business: const {
          'verification_status': 'verified',
          'specialized_field': 'contractor',
        },
      );
      expect(dest, ContractorOnboardingRoutes.specialtyPath);
    });

    test('routes to navigationPath if verified and specialty is set', () {
      final dest = SupabaseAppSession.resolveContractorDestination(
        isBusiness: true,
        business: const {
          'verification_status': 'verified',
          'specialized_field': 'تشطيبات',
        },
      );
      expect(dest, ContractorNavigationRoutes.navigationPath);
    });
  });
}
