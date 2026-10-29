import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_payments_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/presentation/pages/contractor_bank_details_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_contractor_payments_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  const saved = ContractorBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'مصرف الراجحي',
    iban: 'SA0380000000608010167519',
  );

  late FakeContractorPaymentsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeContractorPaymentsRepository();
    registerFakeContractorPayments(repository);
  });

  tearDown(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
  });

  Future<GoRouter> pumpContractor(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) => pumpAppRouter(
    tester,
    session: FakeAppSession()..signIn(AppRole.contractor),
    textScale: textScale,
    boldText: boldText,
  );

  Future<GoRouter> openBankDetails(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpContractor(
      tester,
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(ContractorPaymentsRoutes.bankDetailsName);
    await tester.pumpAndSettle();
    return router;
  }

  Finder field(String name) => find.byKey(Key('contractor_bank_details_$name'));

  Finder button(String name) =>
      find.byKey(Key('contractor_bank_details_$name'));

  VoidCallback? onPressedOf(WidgetTester tester, String name) =>
      tester.widget<AppButton>(button(name)).onPressed;

  Future<void> tap(WidgetTester tester, String name) async {
    await tester.tap(button(name));
    await tester.pumpAndSettle();
  }

  // The form is a list that builds what's on screen: scroll to it first.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        100,
        scrollable: find.byType(Scrollable).first,
      );

  Future<void> type(WidgetTester tester, String name, String text) async {
    await scrollTo(tester, field(name));
    await tester.enterText(field(name), text);
    await tester.pumpAndSettle();
  }

  testWidgets('contractor-bank-details opens at its path, empty on first use', (
    tester,
  ) async {
    final router = await openBankDetails(tester);

    expect(currentPath(router), '/contractor/payments/bank-details');
    expect(find.byType(ContractorBankDetailsPage), findsOneWidget);
    // Why it's needed, and the three fields.
    expect(
      find.text(
        'يحوّل العملاء دفعات مشاريعك إلى هذا الحساب، فتأكد أن البيانات '
        'مطابقة لحسابك في البنك.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(3));
    // Nothing to save yet, and nothing to cancel: the back arrow leaves.
    expect(onPressedOf(tester, 'save'), isNull);
    expect(button('cancel'), findsNothing);
  });

  testWidgets('a pasted account is saved clean, then shown as stored', (
    tester,
  ) async {
    await openBankDetails(tester);

    await type(tester, 'beneficiary', ' مؤسسة البناء المتين ');
    await type(tester, 'bank', 'مصرف الراجحي');
    await type(tester, 'iban', 'sa٠٣ ٨٠٠٠ ٠٠٠٠ ٦٠٨٠ ١٠١٦ ٧٥١٩');
    expect(onPressedOf(tester, 'save'), isNotNull);

    await tap(tester, 'save');

    final added = repository.added.single;
    expect(added.beneficiaryName, 'مؤسسة البناء المتين');
    expect(added.bankName, 'مصرف الراجحي');
    expect(added.iban, 'SA0380000000608010167519');
    expect(find.text('حُفظت بيانات حسابك البنكي'), findsOneWidget);
    // View mode: the IBAN in groups of four, and «تعديل».
    expect(find.byType(TextField), findsNothing);
    expect(find.text('SA03 8000 0000 6080 1016 7519'), findsOneWidget);
    expect(button('edit'), findsOneWidget);
  });

  testWidgets('a wrong check digit shows under the IBAN; «حفظ» stays off', (
    tester,
  ) async {
    await openBankDetails(tester);

    await type(tester, 'beneficiary', 'مؤسسة البناء المتين');
    await type(tester, 'bank', 'مصرف الراجحي');
    await type(tester, 'iban', 'SA0480000000608010167519');

    expect(
      find.text(
        'في هذا الآيبان خطأ؛ أرقام التحقق لا تطابق. قارنه بتطبيق بنكك.',
      ),
      findsOneWidget,
    );
    expect(onPressedOf(tester, 'save'), isNull);
    expect(repository.added, isEmpty);
  });

  testWidgets(
    '«تعديل» opens the form on the saved details; «إلغاء» goes back',
    (tester) async {
      repository.saved = saved;
      await openBankDetails(tester);
      expect(find.text('SA03 8000 0000 6080 1016 7519'), findsOneWidget);

      await tap(tester, 'edit');
      // Filled in, and nothing to save until something changes.
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('مصرف الراجحي'), findsOneWidget);
      expect(find.text('SA03 8000 0000 6080 1016 7519'), findsOneWidget);
      expect(onPressedOf(tester, 'save'), isNull);

      await type(tester, 'bank', 'البنك الأهلي السعودي');
      expect(onPressedOf(tester, 'save'), isNotNull);

      await tap(tester, 'cancel');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('مصرف الراجحي'), findsOneWidget);
      expect(repository.updated, isEmpty);
    },
  );

  testWidgets('a change is saved as an update', (tester) async {
    repository.saved = saved;
    await openBankDetails(tester);

    await tap(tester, 'edit');
    await type(tester, 'bank', 'البنك الأهلي السعودي');
    await tap(tester, 'save');

    expect(repository.updated.single.bankName, 'البنك الأهلي السعودي');
    expect(repository.added, isEmpty);
    expect(find.text('البنك الأهلي السعودي'), findsOneWidget);
    expect(find.text('حُفظت بيانات حسابك البنكي'), findsOneWidget);
  });

  testWidgets('«نسخ» copies the IBAN without spaces', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add(
            (call.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    repository.saved = saved;
    await openBankDetails(tester);

    await tester.tap(find.text('نسخ'));
    await tester.pumpAndSettle();

    expect(copied, ['SA0380000000608010167519']);
    expect(find.text('تم النسخ'), findsOneWidget);
  });

  testWidgets('a page that couldn\'t load says why, and loads again', (
    tester,
  ) async {
    repository.readResult = const Failed(NetworkFailure());
    await openBankDetails(tester);
    expect(find.byType(AppErrorView), findsOneWidget);

    repository
      ..readResult = null
      ..saved = saved;
    await tester.tap(
      find.descendant(
        of: find.byType(AppErrorView),
        matching: find.byType(AppButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsNothing);
    expect(find.text('SA03 8000 0000 6080 1016 7519'), findsOneWidget);
  });

  testWidgets('view mode fits large, bold text', (tester) async {
    repository.saved = saved;
    await openBankDetails(tester, textScale: largeTextScale, boldText: true);

    await scrollTo(tester, find.text('SA03 8000 0000 6080 1016 7519'));
    expect(button('edit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit mode fits large, bold text, errors included', (
    tester,
  ) async {
    repository.saved = saved;
    await openBankDetails(tester, textScale: largeTextScale, boldText: true);

    await tap(tester, 'edit');
    await type(tester, 'iban', 'SA0480000000608010167519');

    expect(
      find.text(
        'في هذا الآيبان خطأ؛ أرقام التحقق لا تطابق. قارنه بتطبيق بنكك.',
      ),
      findsOneWidget,
    );
    expect(button('cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first-use form fits large, bold text', (tester) async {
    await openBankDetails(tester, textScale: largeTextScale, boldText: true);

    await scrollTo(tester, field('iban'));
    expect(button('save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('bank_details_missing links to the bank details screen', () {
    final link = AppNotificationLinks.linkOf(const {
      'type': 'bank_details_missing',
    });

    expect(link?.name, ContractorPaymentsRoutes.bankDetailsName);
    expect(link?.pathParameters, isEmpty);
  });

  testWidgets('the reminder opens the screen on top, like a tapped toast', (
    tester,
  ) async {
    final router = await pumpContractor(tester);
    final link = AppNotificationLinks.linkOf(const {
      'type': 'bank_details_missing',
    })!;

    // As NotificationNavigator does it. It completes when the page closes.
    unawaited(
      router.pushNamed<void>(link.name, pathParameters: link.pathParameters),
    );
    await tester.pumpAndSettle();

    // A pushed page keeps the address it was pushed from, so only the page
    // is checked here; the path is checked when the route is opened by name.
    expect(find.byType(ContractorBankDetailsPage), findsOneWidget);
  });
}
