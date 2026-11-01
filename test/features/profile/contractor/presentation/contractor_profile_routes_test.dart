import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/router/routes/contractor_profile_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';
import 'package:watad/features/kyc/contractor/presentation/pages/contractor_license_page.dart';
import 'package:watad/features/profile/contractor/presentation/pages/contractor_profile_page.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_profile_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  /// The fake contractor, with [status], [specialty] and suspension changed.
  MyProfile contractor({
    VerificationStatus status = VerificationStatus.verified,
    String specialty = 'مقاولات عامة',
    bool isSuspended = false,
  }) => MyProfile(
    id: fakeContractorProfile.id,
    fullName: fakeContractorProfile.fullName,
    isSuspended: isSuspended,
    suspensionReason: isSuspended ? 'شكاوى متكررة من العملاء' : null,
    business: MyProfileBusiness(
      companyName: 'مؤسسة البناء المتين',
      crNumber: '1010123456',
      specializedField: specialty,
      verificationStatus: status,
    ),
  );

  late FakeProfileRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeProfileRepository(profileResult: Success(contractor()));
    registerFakeContractorProfile(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openProfile(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.contractor),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(ContractorProfileRoutes.profileName);
    await tester.pumpAndSettle();
    return router;
  }

  Finder statusRow() => find.byKey(const Key('contractor_profile_status'));

  // The tab is a list that builds what's on screen: scroll to it first.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        100,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('contractor-profile opens «منشأتي» with the business', (
    tester,
  ) async {
    final router = await openProfile(tester);

    expect(currentPath(router), ContractorProfileRoutes.profilePath);
    expect(find.byType(ContractorProfilePage), findsOneWidget);
    expect(find.text('منشأتي'), findsOneWidget);
    expect(find.byType(AppVerifiedName), findsOneWidget);
    expect(find.text('1010123456'), findsOneWidget);
    expect(find.text('مقاولات عامة'), findsOneWidget);
    expect(find.text('موثّقة'), findsOneWidget);
    // Verified: nothing to ask for, so the status only shows.
    expect(tester.widget<AppMenuRow>(statusRow()).onTap, isNull);
  });

  testWidgets('an unverified business can ask for verification again', (
    tester,
  ) async {
    repository.profileResult = Success(
      contractor(status: VerificationStatus.unverified),
    );
    await openProfile(tester);

    expect(find.byType(AppVerifiedName), findsNothing);
    expect(find.text('غير موثّقة'), findsOneWidget);
    expect(find.text('ارفع السجل التجاري لتوثيق منشأتك'), findsOneWidget);
    expect(tester.widget<AppMenuRow>(statusRow()).onTap, isNotNull);
  });

  testWidgets(
    'the status row opens the license upload one way, as the sign-in does',
    (tester) async {
      getIt.registerFactory(
        () => ContractorLicenseBloc(
          ContractorUploadLicenseUseCase(_FakeContractorKycRepository()),
        ),
      );
      repository.profileResult = Success(
        contractor(status: VerificationStatus.unverified),
      );
      final router = await openProfile(tester);

      await tester.tap(statusRow());
      await tester.pumpAndSettle();

      expect(currentPath(router), ContractorKycRoutes.licensePath);
      expect(find.byType(ContractorLicensePage), findsOneWidget);
      expect(find.byType(ContractorProfilePage), findsNothing);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets('a pending business waits: its status only shows', (
    tester,
  ) async {
    repository.profileResult = Success(
      contractor(status: VerificationStatus.pending),
    );
    await openProfile(tester);

    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(tester.widget<AppMenuRow>(statusRow()).onTap, isNull);
  });

  testWidgets('a specialty saved in English reads in Arabic', (tester) async {
    repository.profileResult = Success(contractor(specialty: 'Restoration'));
    await openProfile(tester);

    expect(find.text('ترميم'), findsOneWidget);
  });

  testWidgets('the sign-up default shows no specialty', (tester) async {
    repository.profileResult = Success(contractor(specialty: 'contractor'));
    await openProfile(tester);

    expect(find.text('لم يُحدَّد التخصص'), findsOneWidget);
  });

  testWidgets('a verified «منشأتي» fits large, bold text', (tester) async {
    await openProfile(tester, textScale: largeTextScale, boldText: true);

    await scrollTo(tester, find.byKey(const Key('profile_menu_settings')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a suspended «منشأتي» with its banner fits large, bold text', (
    tester,
  ) async {
    repository.profileResult = Success(
      contractor(status: VerificationStatus.suspended, isSuspended: true),
    );
    await openProfile(tester, textScale: largeTextScale, boldText: true);

    expect(find.text('حسابك موقوف'), findsOneWidget);
    expect(find.text('شكاوى متكررة من العملاء'), findsOneWidget);
    await scrollTo(tester, statusRow());
    expect(find.text('موقوفة'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('profile_menu_settings')));
    expect(tester.takeException(), isNull);
  });
}

/// The license page's repository: this test only opens the page.
class _FakeContractorKycRepository implements ContractorKycRepository {
  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> signOut() async => const Success(null);
}
