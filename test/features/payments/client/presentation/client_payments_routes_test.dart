import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_payments_routes.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_bank_transfer_bloc.dart';
import 'package:watad/features/payments/client/presentation/pages/client_bank_transfer_page.dart';
import 'package:watad/features/payments/client/presentation/pages/client_new_payment_page.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_tasks_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_payments_repository.dart';
import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  ClientPaymentTask task(
    String id,
    String title, {
    TaskStatus status = TaskStatus.approved,
    int? halalas = 1500000,
    String? paymentId = 'pay',
    PaymentStatus? paymentStatus = PaymentStatus.pending,
  }) => ClientPaymentTask(
    id: id,
    title: title,
    status: status,
    amount: halalas == null ? null : Money.halalas(halalas),
    paymentId: paymentId == null ? null : '$paymentId-$id',
    paymentStatus: paymentStatus,
  );
  // One task for each reason, and two to pay.
  final tasks = [
    task('t-1', 'الحفر والأساسات', paymentStatus: PaymentStatus.paid),
    task('t-2', 'الهيكل الخرساني', paymentStatus: PaymentStatus.processing),
    task('t-3', 'اللياسة الداخلية'),
    task('t-4', 'الدهانات', halalas: 2400000),
    task('t-5', 'تمديدات الكهرباء', status: TaskStatus.accepted),
    task('t-6', 'تنظيف الموقع', halalas: null),
    task('t-7', 'السور', paymentStatus: PaymentStatus.cancelled),
    task('t-8', 'العزل المائي', status: TaskStatus.rejected),
  ];
  const bankDetails = ClientBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'مصرف الراجحي',
    iban: 'SA0380000000608010167519',
  );
  final pdf = ClientReceipt(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'receipt.pdf',
  );

  late FakeClientPaymentsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeClientPaymentsRepository()
      ..tasksResult = Success(tasks)
      ..bankDetailsResult = const Success(bankDetails);
    registerFakeClientPayments(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openNewPayment(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      ClientPaymentsRoutes.newPaymentName,
      pathParameters: {'projectId': 'p-3'},
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder row(String taskId) =>
      find.byKey(ValueKey('client_payment_task_$taskId'));

  AppCheckbox checkboxOf(WidgetTester tester, String taskId) =>
      tester.widget<AppCheckbox>(
        find.descendant(of: row(taskId), matching: find.byType(AppCheckbox)),
      );

  // The total is under the list: scroll to it first.
  Future<String?> totalOf(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byType(AppSummaryRows),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    return tester
        .widget<AppSummaryRows>(find.byType(AppSummaryRows))
        .total
        ?.value;
  }

  testWidgets('client-new-payment lists the tasks at its path, with why', (
    tester,
  ) async {
    final router = await openNewPayment(tester);

    expect(currentPath(router), '/client/payments/p-3/new');
    expect(find.byType(ClientNewPaymentPage), findsOneWidget);
    // The rejected task isn't part of the work.
    expect(find.text('العزل المائي'), findsNothing);
    // Why the others can't be paid.
    expect(find.text('مدفوعة'), findsOneWidget);
    expect(find.text('بانتظار تأكيد المقاول'), findsOneWidget);
    expect(find.text('لم تُعتمد بعد'), findsOneWidget);
    expect(find.text('لا يوجد مبلغ لدفعه'), findsOneWidget);
    expect(find.text('غير متاحة للدفع'), findsOneWidget);
    // Only the finished, approved, unpaid tasks can be ticked.
    for (final id in ['t-1', 't-2', 't-5', 't-6', 't-7']) {
      expect(checkboxOf(tester, id).onChanged, isNull, reason: id);
    }
    expect(checkboxOf(tester, 't-3').onChanged, isNotNull);
    expect(checkboxOf(tester, 't-4').onChanged, isNotNull);
    expect(await totalOf(tester), '٠ ر.س');
  });

  testWidgets('the total follows the ticked tasks', (tester) async {
    repository.tasksResult = Success([tasks[0], tasks[2], tasks[3]]);
    await openNewPayment(tester);
    Future<void> tick(String taskId) async {
      await tester.ensureVisible(row(taskId));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: row(taskId), matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
    }

    await tick('t-3');
    expect(checkboxOf(tester, 't-3').value, isTrue);
    expect(await totalOf(tester), '١٥٬٠٠٠ ر.س');

    await tick('t-4');
    expect(await totalOf(tester), '٣٩٬٠٠٠ ر.س');

    await tick('t-3');
    expect(checkboxOf(tester, 't-3').value, isFalse);
    expect(await totalOf(tester), '٢٤٬٠٠٠ ر.س');
  });

  testWidgets('nothing to pay says so', (tester) async {
    repository.tasksResult = Success([
      task('t-1', 'الحفر والأساسات', paymentStatus: PaymentStatus.paid),
      task('t-5', 'تمديدات الكهرباء', status: TaskStatus.accepted),
    ]);
    await openNewPayment(tester);

    expect(find.text('لا توجد مهام جاهزة للدفع بعد'), findsOneWidget);
    expect(find.byType(AppSummaryRows), findsNothing);
  });

  testWidgets('the task selection fits large, bold text', (tester) async {
    await openNewPayment(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(ClientNewPaymentPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<GoRouter> pumpClient(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) => pumpAppRouter(
    tester,
    session: FakeAppSession()..signIn(AppRole.client),
    textScale: textScale,
    boldText: boldText,
  );

  // The transfer for t-3 and t-4, on top of the task selection, as
  // «متابعة» opens it.
  Future<GoRouter> openTransfer(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpClient(
      tester,
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      ClientPaymentsRoutes.newPaymentName,
      pathParameters: {'projectId': 'p-3'},
    );
    await tester.pumpAndSettle();
    // It completes when the page closes, which the tests check on screen.
    unawaited(
      router.pushNamed<bool>(
        ClientPaymentsRoutes.bankTransferName,
        pathParameters: {'projectId': 'p-3'},
        queryParameters: {'taskIds': 't-3,t-4'},
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  // The phone's pickers aren't in tests: the bloc gets the file.
  Future<void> attach(WidgetTester tester, ClientReceipt receipt) async {
    tester
        .element(find.byType(ClientBankTransferPage))
        .read<ClientBankTransferBloc>()
        .add(ClientBankTransferReceiptPicked(receipt));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  Finder send() => find.byKey(const Key('client_bank_transfer_send'));

  testWidgets('client-bank-transfer shows where to send the money', (
    tester,
  ) async {
    final router = await pumpClient(tester);
    router.goNamed(
      ClientPaymentsRoutes.bankTransferName,
      pathParameters: {'projectId': 'p-3'},
      queryParameters: {'taskIds': 't-3,t-4'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/client/payments/p-3/transfer');
    expect(find.byType(ClientBankTransferPage), findsOneWidget);
    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('مصرف الراجحي'), findsOneWidget);
    expect(find.text('SA03 8000 0000 6080 1016 7519'), findsOneWidget);
    expect(find.text('٣٩٬٠٠٠ ر.س'), findsWidgets);
    // The tasks it pays, and their total.
    await scrollTo(tester, find.byType(AppSummaryRows));
    expect(find.text('اللياسة الداخلية'), findsOneWidget);
    expect(find.text('الدهانات'), findsOneWidget);
    expect(
      tester.widget<AppSummaryRows>(find.byType(AppSummaryRows)).total?.value,
      '٣٩٬٠٠٠ ر.س',
    );
    // No transfer date or transaction number: the receipt is the proof.
    expect(find.byType(TextField), findsNothing);
    // Nothing to send before a receipt.
    expect(tester.widget<AppButton>(send()).onPressed, isNull);
  });

  testWidgets('Copy gives the IBAN without spaces, the amount as a number', (
    tester,
  ) async {
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
    await openTransfer(tester);

    await tester.tap(find.text('نسخ').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نسخ').at(1));
    await tester.pumpAndSettle();

    expect(copied, ['SA0380000000608010167519', '39000']);
    expect(find.text('تم النسخ'), findsOneWidget);
  });

  testWidgets('without the contractor\'s bank details, nothing to send', (
    tester,
  ) async {
    repository.bankDetailsResult = const Success(null);
    await openTransfer(tester);

    expect(
      find.text('لم يُضف المقاول بيانات حسابه البنكي بعد'),
      findsOneWidget,
    );
    expect(send(), findsNothing);
    expect(find.byKey(const Key('client_bank_transfer_receipt')), findsNothing);
  });

  testWidgets('the receipt box opens the choice of a file or a photo', (
    tester,
  ) async {
    await openTransfer(tester);
    final box = find.byKey(const Key('client_bank_transfer_receipt'));
    await scrollTo(tester, box);
    await tester.tap(box);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('client_receipt_from_file')), findsOneWidget);
    expect(find.byKey(const Key('client_receipt_from_photos')), findsOneWidget);
  });

  testWidgets('a receipt turns sending on; a HEIC photo is refused', (
    tester,
  ) async {
    await openTransfer(tester);

    await attach(
      tester,
      ClientReceipt(bytes: Uint8List.fromList([1]), name: 'IMG_0001.HEIC'),
    );
    expect(find.text('ارفع ملف PDF أو صورة JPEG أو PNG.'), findsOneWidget);
    expect(tester.widget<AppButton>(send()).onPressed, isNull);

    await attach(tester, pdf);
    await scrollTo(
      tester,
      find.byKey(const Key('client_bank_transfer_receipt')),
    );
    expect(find.text('الإيصال: receipt.pdf'), findsOneWidget);
    expect(tester.widget<AppButton>(send()).onPressed, isNotNull);
  });

  testWidgets('a sending that stops part way says what went; again, the rest', (
    tester,
  ) async {
    repository.failingPayments['pay-t-4'] = const NetworkFailure();
    await openTransfer(tester);
    await attach(tester, pdf);

    await tester.tap(send());
    await tester.pumpAndSettle();
    expect(repository.submitted.map((s) => s.$1), ['pay-t-3']);
    expect(find.text('لم يُرسل الإيصال لكل المهام'), findsOneWidget);
    expect(find.text('إرسال الإيصال لباقي المهام'), findsOneWidget);

    repository.failingPayments.clear();
    await tester.tap(send());
    await tester.pumpAndSettle();
    expect(repository.submitted.map((s) => s.$1), ['pay-t-3', 'pay-t-4']);
    expect(find.text('أُرسل الإيصال للمقاول'), findsOneWidget);
    expect(find.byType(ClientBankTransferPage), findsNothing);
  });

  testWidgets('paying from the timeline ends back on the timeline', (
    tester,
  ) async {
    registerFakeClientProjects(
      FakeClientProjectsRepository()
        ..projectResult = Success(
          ClientProject(
            id: 'p-3',
            title: 'بناء ملحق',
            status: ProjectStatus.inProgress,
            city: 'جدة',
            pendingOfferCount: 0,
            createdAt: DateTime.utc(2026, 10, 17),
          ),
        ),
    );
    final router = await pumpClient(tester);
    router.goNamed(
      ClientProjectsRoutes.projectTasksName,
      pathParameters: {'projectId': 'p-3'},
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('client_project_tasks_pay')));
    await tester.pumpAndSettle();
    for (final id in ['t-3', 't-4']) {
      await tester.ensureVisible(row(id));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: row(id), matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('client_new_payment_continue')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ClientBankTransferPage>(find.byType(ClientBankTransferPage))
          .selection
          .taskIds,
      ['t-3', 't-4'],
    );

    await attach(tester, pdf);
    await tester.tap(send());
    await tester.pumpAndSettle();

    expect(repository.submitted, [
      ('pay-t-3', 'receipt.pdf'),
      ('pay-t-4', 'receipt.pdf'),
    ]);
    expect(find.text('أُرسل الإيصال للمقاول'), findsOneWidget);
    // Both payment pages closed: the timeline reads the tasks again.
    expect(find.byType(ClientBankTransferPage), findsNothing);
    expect(find.byType(ClientNewPaymentPage), findsNothing);
    expect(find.byType(ClientProjectTasksPage), findsOneWidget);
  });

  testWidgets('the transfer page fits large, bold text', (tester) async {
    await openTransfer(tester, textScale: largeTextScale, boldText: true);
    await attach(tester, pdf);

    expect(find.byType(ClientBankTransferPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
