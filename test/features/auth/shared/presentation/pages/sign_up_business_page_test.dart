import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_phone_field.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';
import '../../../../../helpers/pump_router.dart';

class FakeContractorKycRepository implements ContractorKycRepository {
  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) async => throw UnimplementedError();
}

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
    registerFakeAuthBloc(repository);
    getIt
      ..registerFactory(RoleBloc.new)
      ..registerFactory(
        () => BusinessSignUpBloc(
          SendSignUpOtpUseCase(repository),
          VerifyOtpUseCase(repository),
          SaveBusinessSignUpUseCase(repository),
        ),
      )
      ..registerFactory(
        () => ContractorLicenseBloc(
          ContractorUploadLicenseUseCase(FakeContractorKycRepository()),
        ),
      );
  });

  tearDown(getIt.reset);

  Future<GoRouter> openSignUpBusiness(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = await pumpAppRouter(
      tester,
      initialLocation: AuthRoutes.signUpBusinessPath,
    );
    router.goNamed(AuthRoutes.signUpBusinessName);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shows form elements initially', (tester) async {
    await openSignUpBusiness(tester);

    expect(find.byType(SignUpBusinessPage), findsOneWidget);
    expect(find.text('بيانات المنشأة'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(3));
    expect(find.byType(AppPhoneField), findsOneWidget);
    expect(find.byType(AppCheckbox), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'التالي'), findsOneWidget);
  });

  testWidgets('submitting empty form displays validation errors', (
    tester,
  ) async {
    await openSignUpBusiness(tester);

    await tester.tap(find.widgetWithText(AppButton, 'التالي'));
    await tester.pumpAndSettle();

    expect(find.text('يرجى إدخال اسم المنشأة.'), findsOneWidget);
    expect(find.text('يرجى إدخال رقم السجل التجاري.'), findsOneWidget);
    expect(find.text('يرجى إدخال البريد الإلكتروني.'), findsOneWidget);
    expect(find.text('يرجى إدخال رقم الجوال.'), findsOneWidget);
    expect(
      find.text('يجب الموافقة على الشروط وسياسة الخصوصية للمتابعة.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'submitting valid form moves to OTP step and verifying OTP saves business',
    (tester) async {
      await openSignUpBusiness(tester);

      final textFields = find.descendant(
        of: find.byType(AppTextField),
        matching: find.byType(TextFormField),
      );

      // Company Name
      await tester.enterText(textFields.at(0), 'شركة وتد للمقاولات');
      // CR Number
      await tester.enterText(textFields.at(1), '1010123456');
      // Email
      await tester.enterText(textFields.at(2), 'contractor@watad.sa');

      // Phone
      final phoneField = find.descendant(
        of: find.byType(AppPhoneField),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(phoneField, '501234567');

      // Checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.widgetWithText(AppButton, 'التالي'));
      await tester.pumpAndSettle();

      expect(repository.sentTo, contains('contractor@watad.sa'));
      expect(
        repository.sentToWithCreateUser,
        contains(('contractor@watad.sa', true)),
      );

      // Should now show OTP section
      expect(find.text('رمز التحقق'), findsOneWidget);
      expect(find.byType(AppOtpInput), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'تأكيد'), findsOneWidget);

      // Enter OTP (triggers onCompleted automatically)
      await tester.enterText(find.byType(AppOtpInput), '123456');
      await tester.pumpAndSettle();

      expect(repository.checked, [('contractor@watad.sa', '123456')]);
      expect(repository.savedBusiness?.companyName, 'شركة وتد للمقاولات');
      expect(repository.savedBusiness?.crNumber, '1010123456');
      expect(repository.savedBusiness?.email, 'contractor@watad.sa');
      expect(repository.savedBusiness?.phone, '+966501234567');
      expect(repository.savedBusiness?.specializedField, 'contractor');
    },
  );

  testWidgets('back arrow on OTP section steps back to form section', (
    tester,
  ) async {
    await openSignUpBusiness(tester);

    final textFields = find.descendant(
      of: find.byType(AppTextField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(textFields.at(0), 'شركة وتد');
    await tester.enterText(textFields.at(1), '1010123456');
    await tester.enterText(textFields.at(2), 'c@watad.sa');
    final phoneField = find.descendant(
      of: find.byType(AppPhoneField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(phoneField, '501234567');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'التالي'));
    await tester.pumpAndSettle();

    expect(find.text('رمز التحقق'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Form should be back
    expect(find.text('بيانات المنشأة'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'التالي'), findsOneWidget);
  });
}
