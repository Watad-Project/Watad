import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_profile_routes.dart';
import 'package:watad/core/router/routes/contractor_profile_routes.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/profile/client/presentation/pages/client_profile_page.dart';
import 'package:watad/features/profile/contractor/presentation/pages/contractor_profile_page.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/presentation/pages/profile_edit_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_profile_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  MyProfile contractor({
    VerificationStatus status = VerificationStatus.verified,
  }) => MyProfile(
    id: fakeContractorProfile.id,
    fullName: 'خالد الحربي',
    isSuspended: false,
    business: MyProfileBusiness(
      companyName: 'مؤسسة البناء المتين',
      crNumber: '1010123456',
      specializedField: 'مقاولات عامة',
      verificationStatus: status,
    ),
  );

  late FakeProfileRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeProfileRepository();
  });

  tearDown(getIt.reset);

  /// A contractor's repository: no identity, as most contractors have.
  void useContractor(VerificationStatus status) => repository
    ..profileResult = Success(contractor(status: status))
    ..identityResult = const Success(null);

  Future<GoRouter> pump(
    WidgetTester tester, {
    AppRole role = AppRole.client,
    double textScale = 1,
    bool boldText = false,
  }) => pumpAppRouter(
    tester,
    session: FakeAppSession()..signIn(role),
    textScale: textScale,
    boldText: boldText,
  );

  /// Opens the edit page on its own, by its route.
  Future<GoRouter> openEdit(
    WidgetTester tester, {
    AppRole role = AppRole.client,
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pump(
      tester,
      role: role,
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(ProfileRoutes.profileEditName);
    await tester.pumpAndSettle();
    return router;
  }

  // Lists build what's on screen: scroll to it first.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        100,
        scrollable: find.byType(Scrollable).first,
      );

  // Back on a tab that scrolled to its edit row: scroll up to [finder].
  Future<void> scrollBackTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        -100,
        scrollable: find.byType(Scrollable).first,
      );

  /// Opens the account tab of [route], then its edit row.
  Future<void> openFromTab(WidgetTester tester, String route) async {
    final router = await pump(
      tester,
      role: route == ClientProfileRoutes.profileName
          ? AppRole.client
          : AppRole.contractor,
    );
    router.goNamed(route);
    await tester.pumpAndSettle();
    final edit = find.byKey(const Key('profile_menu_edit'));
    await scrollTo(tester, edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
  }

  Finder field(String name) => find.byKey(Key('profile_edit_$name'));

  VoidCallback? saveOf(WidgetTester tester) =>
      tester.widget<AppButton>(field('save')).onPressed;

  Future<void> type(WidgetTester tester, String name, String text) async {
    await scrollTo(tester, field(name));
    await tester.enterText(field(name), text);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('profile-edit opens the form at its path, nothing to save', (
    tester,
  ) async {
    registerFakeClientProfile(repository);
    final router = await openEdit(tester);

    expect(currentPath(router), ProfileRoutes.profileEditPath);
    expect(find.byType(ProfileEditPage), findsOneWidget);
    expect(find.text('سارة العتيبي'), findsOneWidget);
    expect(saveOf(tester), isNull);
  });

  testWidgets("a client's identity is read-only, the phone in groups", (
    tester,
  ) async {
    registerFakeClientProfile(repository);
    await openEdit(tester);

    await scrollTo(tester, find.text('+966 51 234 5678'));
    expect(find.text('1012345678'), findsOneWidget);
    expect(find.text('لا يمكن تغيير هذه البيانات.'), findsOneWidget);
    // No business part for a client.
    expect(field('company_name'), findsNothing);
  });

  testWidgets('a new name is saved, and «حسابي» shows it', (tester) async {
    registerFakeClientProfile(repository);
    await openFromTab(tester, ClientProfileRoutes.profileName);

    await type(tester, 'name', 'سارة محمد العتيبي');
    expect(saveOf(tester), isNotNull);
    await tester.tap(field('save'));
    await tester.pumpAndSettle();

    expect(repository.userWrites.single.fullName, 'سارة محمد العتيبي');
    expect(find.byType(ClientProfilePage), findsOneWidget);
    expect(find.text('حُفظت التغييرات.'), findsOneWidget);
    await scrollBackTo(tester, find.text('سارة محمد العتيبي'));
    expect(find.text('سارة محمد العتيبي'), findsOneWidget);
  });

  testWidgets('leaving with changes asks first', (tester) async {
    registerFakeClientProfile(repository);
    await openFromTab(tester, ClientProfileRoutes.profileName);
    await type(tester, 'name', 'سارة محمد العتيبي');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('الخروج دون حفظ؟'), findsOneWidget);

    // «إلغاء» stays on the form.
    await tapText(tester, 'إلغاء');
    expect(find.byType(ProfileEditPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tapText(tester, 'خروج');

    expect(find.byType(ClientProfilePage), findsOneWidget);
    await scrollBackTo(tester, find.text('سارة العتيبي'));
    expect(find.text('سارة العتيبي'), findsOneWidget);
    expect(repository.userWrites, isEmpty);
  });

  testWidgets('a verified business: the CR number is locked', (tester) async {
    useContractor(VerificationStatus.verified);
    registerFakeContractorProfile(repository);
    await openEdit(tester, role: AppRole.contractor);

    await scrollTo(tester, field('cr_number_locked'));
    expect(
      find.text('لا يمكن تعديل السجل التجاري بعد التوثيق'),
      findsOneWidget,
    );
    expect(find.text('1010123456'), findsOneWidget);
    expect(field('cr_number'), findsNothing);
    // No v_my_identity row: no identity section.
    expect(find.text('بيانات الهوية'), findsNothing);
  });

  testWidgets(
    'a new company name on a verified business warns first; confirming saves '
    'and «منشأتي» shows it unverified',
    (tester) async {
      useContractor(VerificationStatus.verified);
      registerFakeContractorProfile(repository);
      await openFromTab(tester, ContractorProfileRoutes.profileName);

      await type(tester, 'company_name', 'مؤسسة البناء الحديث');
      await tester.tap(field('save'));
      await tester.pumpAndSettle();

      expect(find.text('ستفقد منشأتك التوثيق'), findsOneWidget);
      await tapText(tester, 'نعم، احفظ');

      expect(
        repository.businessWrites.single.companyName,
        'مؤسسة البناء الحديث',
      );
      expect(find.byType(ContractorProfilePage), findsOneWidget);
      await scrollBackTo(tester, find.text('غير موثّقة'));
      expect(find.text('غير موثّقة'), findsOneWidget);
      expect(
        find.text(
          'حُفظت التغييرات. منشأتك الآن غير موثّقة؛ ارفع السجل التجاري '
          'لتوثيقها من جديد.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('cancelling the warning keeps the form, unsaved', (tester) async {
    useContractor(VerificationStatus.verified);
    registerFakeContractorProfile(repository);
    await openEdit(tester, role: AppRole.contractor);

    await type(tester, 'company_name', 'مؤسسة البناء الحديث');
    await tester.tap(field('save'));
    await tester.pumpAndSettle();
    await tapText(tester, 'إلغاء');

    expect(find.byType(ProfileEditPage), findsOneWidget);
    expect(repository.businessWrites, isEmpty);
    expect(saveOf(tester), isNotNull);
  });

  testWidgets('a taken CR number says so under the field', (tester) async {
    useContractor(VerificationStatus.unverified);
    repository.updateBusinessResult = const Failed(ConflictFailure());
    registerFakeContractorProfile(repository);
    await openEdit(tester, role: AppRole.contractor);

    await type(tester, 'cr_number', '٢٠٥٠١٢٣٤٥٦');
    await tester.tap(field('save'));
    await tester.pumpAndSettle();

    // Unverified: no warning. The number went out in Latin digits.
    expect(repository.businessWrites.single.crNumber, '2050123456');
    expect(find.byType(ProfileEditPage), findsOneWidget);
    expect(find.text('رقم السجل التجاري هذا مسجّل لمنشأة أخرى.'), findsWidgets);
  });

  testWidgets('a suspended user sees why, and nothing can be saved', (
    tester,
  ) async {
    repository.profileResult = const Success(
      MyProfile(
        id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        fullName: 'سارة العتيبي',
        isSuspended: true,
        suspensionReason: 'مخالفة شروط الاستخدام',
      ),
    );
    registerFakeClientProfile(repository);
    await openEdit(tester);

    expect(find.text('حسابك موقوف'), findsOneWidget);
    expect(find.text('مخالفة شروط الاستخدام'), findsOneWidget);
    final name = tester.widget<TextField>(
      find.descendant(of: field('name'), matching: find.byType(TextField)),
    );
    expect(name.enabled, isFalse);
    expect(saveOf(tester), isNull);
  });

  testWidgets("a client's form fits large, bold text", (tester) async {
    registerFakeClientProfile(repository);
    await openEdit(tester, textScale: largeTextScale, boldText: true);

    await scrollTo(tester, find.text('+966 51 234 5678'));
    expect(tester.takeException(), isNull);
  });

  testWidgets("a verified contractor's form fits large, bold text", (
    tester,
  ) async {
    useContractor(VerificationStatus.verified);
    registerFakeContractorProfile(repository);
    await openEdit(
      tester,
      role: AppRole.contractor,
      textScale: largeTextScale,
      boldText: true,
    );

    await scrollTo(tester, field('cr_number_locked'));
    expect(tester.takeException(), isNull);
  });

  testWidgets("an unverified contractor's form fits large, bold text", (
    tester,
  ) async {
    useContractor(VerificationStatus.unverified);
    registerFakeContractorProfile(repository);
    await openEdit(
      tester,
      role: AppRole.contractor,
      textScale: largeTextScale,
      boldText: true,
    );

    await scrollTo(tester, field('cr_number'));
    expect(tester.takeException(), isNull);
  });
}
