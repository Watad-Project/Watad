import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_summary_rows.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_payments_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/presentation/pages/client_new_payment_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_payments_repository.dart';
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

  late FakeClientPaymentsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeClientPaymentsRepository()..tasksResult = Success(tasks);
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
}
