import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  Widget buildPage({ClientPostProjectBloc? bloc}) {
    return BlocProvider(
      create: (_) => bloc ?? ClientPostProjectBloc(),
      child: const ClientPostProjectPage(),
    );
  }

  group('ClientPostProjectPage - Step 1', () {
    testWidgets('renders Arabic strings, dropdown, and disabled next button', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildPage());

      expect(find.text('الخطوة ١'), findsOneWidget);
      expect(find.text('ما نوع مشروعك؟'), findsOneWidget);
      expect(
        find.text('يحدد النوع إن كان صك الملكية مطلوباً قبل النشر.'),
        findsOneWidget,
      );
      expect(find.text('اختر النوع'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      final nextButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('opens dropdown and displays the three options with hints', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildPage());

      await tester.tap(find.text('اختر النوع'));
      await tester.pumpAndSettle();

      expect(find.text('تأسيس منزل'), findsOneWidget);
      expect(find.text('ترميم منزل'), findsOneWidget);
      expect(find.text('إصلاحات داخل المنزل'), findsOneWidget);
      expect(find.text('يتطلب صك الملكية'), findsNWidgets(2));
      expect(find.text('لا يلزم صك — يُنشر مباشرة'), findsOneWidget);
    });

    testWidgets('choosing an option enables the next button', (tester) async {
      final bloc = ClientPostProjectBloc();
      await pumpLocalizedApp(tester, buildPage(bloc: bloc));

      await tester.tap(find.text('اختر النوع'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تأسيس منزل'));
      await tester.pumpAndSettle();

      expect(bloc.state.projectType, ClientProjectType.newHouse);
      expect(bloc.state.canProceedFromStep1, isTrue);

      final nextButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('tapping next button advances to step 2', (tester) async {
      final bloc = ClientPostProjectBloc();
      await pumpLocalizedApp(tester, buildPage(bloc: bloc));

      await tester.tap(find.text('اختر النوع'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إصلاحات داخل المنزل'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(bloc.state.currentStep, 2);
    });

    testWidgets('renders English strings when locale is English', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildPage(),
        locale: AppLocalization.english,
      );

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('What is your project type?'), findsOneWidget);
      expect(
        find.text(
          'The type determines whether a property deed is required before publishing.',
        ),
        findsOneWidget,
      );
      expect(find.text('Select type'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('ClientPostProjectPage - Step 2', () {
    testWidgets(
      'Variant A: renders deed-required fields, photo row, and deed next button',
      (tester) async {
        final bloc = ClientPostProjectBloc()
          ..add(
            const ClientPostProjectTypeSelected(ClientProjectType.renovation),
          )
          ..add(const ClientPostProjectStepAdvanced());

        await pumpLocalizedApp(tester, buildPage(bloc: bloc));
        await tester.pumpAndSettle();

        expect(find.text('الخطوة 2 من 4'), findsOneWidget);
        expect(find.text('تفاصيل المشروع'), findsOneWidget);
        expect(find.text('ترميم منزل'), findsOneWidget);
        expect(find.text('يتطلب صك'), findsOneWidget);
        expect(find.text('نطاق العمل'), findsOneWidget);
        expect(find.text('الميزانية (ر.س)'), findsOneWidget);
        expect(find.text('موقع المشروع'), findsOneWidget);
        expect(find.text('الرياض · حي المروج'), findsOneWidget);
        expect(find.text('تغيير على الخريطة'), findsOneWidget);
        expect(find.text('التالي — توثيق الملكية'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        final nextButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(nextButton.onPressed, isNull);
      },
    );

    testWidgets(
      'Variant B: renders repairs fields, info banner, and review next button',
      (tester) async {
        final bloc = ClientPostProjectBloc()
          ..add(const ClientPostProjectTypeSelected(ClientProjectType.repairs))
          ..add(const ClientPostProjectStepAdvanced());

        await pumpLocalizedApp(tester, buildPage(bloc: bloc));
        await tester.pumpAndSettle();

        expect(find.text('الخطوة 2 من 3'), findsOneWidget);
        expect(find.text('تفاصيل المشروع'), findsOneWidget);
        expect(find.text('إصلاحات داخل المنزل'), findsOneWidget);
        expect(find.text('لا يلزم صك'), findsOneWidget);
        expect(find.text('لا حاجة لصك الملكية'), findsOneWidget);
        expect(
          find.text('يُنشر المشروع مباشرة بعد المراجعة وتُفتح العروض.'),
          findsOneWidget,
        );
        expect(find.byType(AppStatusCard), findsOneWidget);
        expect(find.text('التالي — المراجعة والنشر'), findsOneWidget);
      },
    );

    testWidgets(
      'entering valid scope and budget enables next button in step 2',
      (tester) async {
        final bloc = ClientPostProjectBloc()
          ..add(const ClientPostProjectTypeSelected(ClientProjectType.repairs))
          ..add(const ClientPostProjectStepAdvanced());

        await pumpLocalizedApp(tester, buildPage(bloc: bloc));
        await tester.pumpAndSettle();

        final textFields = find.byType(AppTextField);
        // Scope field
        await tester.enterText(textFields.at(0), 'Leak repair');
        // Min budget
        await tester.enterText(textFields.at(1), '2000');
        // Max budget
        await tester.enterText(textFields.at(2), '4000');
        await tester.pumpAndSettle();

        expect(bloc.state.canProceedFromStep2, isTrue);
        final nextButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(nextButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'changing project type in step 2 dynamically updates variant and step count',
      (tester) async {
        final bloc = ClientPostProjectBloc()
          ..add(
            const ClientPostProjectTypeSelected(ClientProjectType.renovation),
          )
          ..add(const ClientPostProjectStepAdvanced());

        await pumpLocalizedApp(tester, buildPage(bloc: bloc));
        await tester.pumpAndSettle();

        expect(find.text('الخطوة 2 من 4'), findsOneWidget);
        expect(find.text('التالي — توثيق الملكية'), findsOneWidget);

        // Open dropdown in Step 2
        await tester.tap(find.text('ترميم منزل'));
        await tester.pumpAndSettle();

        // Switch to repairs
        await tester.tap(find.text('إصلاحات داخل المنزل'));
        await tester.pumpAndSettle();

        expect(find.text('الخطوة 2 من 3'), findsOneWidget);
        expect(find.text('التالي — المراجعة والنشر'), findsOneWidget);
        expect(find.text('لا حاجة لصك الملكية'), findsOneWidget);
      },
    );

    testWidgets('renders English strings for step 2', (tester) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
        ..add(const ClientPostProjectStepAdvanced());

      await pumpLocalizedApp(
        tester,
        buildPage(bloc: bloc),
        locale: AppLocalization.english,
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Project details'), findsOneWidget);
      expect(find.text('Scope of work'), findsOneWidget);
      expect(find.text('Budget (SAR)'), findsOneWidget);
      expect(find.text('Project location'), findsOneWidget);
      expect(find.text('Next — Property Deed'), findsOneWidget);
    });
  });

  group('ClientPostProjectPage - Step 3', () {
    testWidgets('renders Step 3 initial upload state when deed is required', (
      tester,
    ) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
        ..add(const ClientPostProjectStepAdvanced())
        ..add(const ClientPostProjectStepAdvanced());

      await pumpLocalizedApp(tester, buildPage(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('الخطوة 3 من 4'), findsOneWidget);
      expect(find.text('صك ملكية العقار أو الأرض'), findsOneWidget);
      expect(
        find.text(
          'مطلوب لمشاريع التأسيس والترميم فقط. بعد اعتماده يصبح المشروع مرئياً للمقاولين وتُفتح العروض.',
        ),
        findsOneWidget,
      );
      expect(find.text('١ · لم يُرفع بعد — تصوير أو رفع الصك'), findsOneWidget);
      expect(find.byType(AppUploadZone), findsOneWidget);
      expect(find.text('التالي — المراجعة والنشر'), findsOneWidget);

      final nextButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(nextButton.onPressed, isNull);
    });

    testWidgets(
      'tapping upload zone uploads deed and transitions to under review',
      (tester) async {
        final bloc = ClientPostProjectBloc()
          ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
          ..add(const ClientPostProjectStepAdvanced())
          ..add(const ClientPostProjectStepAdvanced());

        await pumpLocalizedApp(tester, buildPage(bloc: bloc));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppUploadZone));
        await tester.pumpAndSettle();

        expect(bloc.state.deedStatus, ClientDeedVerificationStatus.underReview);
        expect(find.text('٢ · قيد المراجعة'), findsOneWidget);
        expect(
          find.text(
            'حُفظ المشروع كمسودة وهو غير مرئي للمقاولين حتى اعتماد الصك.',
          ),
          findsOneWidget,
        );

        final nextButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(nextButton.onPressed, isNotNull);
      },
    );

    testWidgets('renders verified deed state and enables next button', (
      tester,
    ) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
        ..add(const ClientPostProjectStepAdvanced())
        ..add(const ClientPostProjectStepAdvanced())
        ..add(
          const ClientPostProjectDeedStatusChanged(
            ClientDeedVerificationStatus.verified,
          ),
        );

      await pumpLocalizedApp(tester, buildPage(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('٣ · موثّق'), findsOneWidget);
      expect(
        find.text(
          'المشروع منشور، والعروض مفتوحة. تظهر علامة «ملكية موثّقة» للمقاولين.',
        ),
        findsOneWidget,
      );

      final nextButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets(
      'renders rejected deed card with retry button and disables next',
      (tester) async {
        final bloc = ClientPostProjectBloc()
          ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
          ..add(const ClientPostProjectStepAdvanced())
          ..add(const ClientPostProjectStepAdvanced())
          ..add(
            const ClientPostProjectDeedStatusChanged(
              ClientDeedVerificationStatus.rejected,
              rejectionReason: 'مرفوض — اسم المالك لا يطابق الهوية',
            ),
          );

        await pumpLocalizedApp(tester, buildPage(bloc: bloc));
        await tester.pumpAndSettle();

        expect(find.text('مرفوض — اسم المالك لا يطابق الهوية'), findsOneWidget);
        expect(find.text('إعادة الرفع'), findsOneWidget);

        // Next button is disabled
        final nextButton = tester.widget<AppButton>(
          find.byWidgetPredicate(
            (w) => w is AppButton && w.label == 'التالي — المراجعة والنشر',
          ),
        );
        expect(nextButton.onPressed, isNull);

        // Tap retry button
        await tester.tap(find.text('إعادة الرفع'));
        await tester.pumpAndSettle();

        expect(bloc.state.deedStatus, ClientDeedVerificationStatus.none);
        expect(find.byType(AppUploadZone), findsOneWidget);
        expect(
          find.text('١ · لم يُرفع بعد — تصوير أو رفع الصك'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders English strings for step 3', (tester) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
        ..add(const ClientPostProjectStepAdvanced())
        ..add(const ClientPostProjectStepAdvanced());

      await pumpLocalizedApp(
        tester,
        buildPage(bloc: bloc),
        locale: AppLocalization.english,
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('Property or Land Ownership Deed'), findsOneWidget);
      expect(
        find.text('1 · Not uploaded yet — Photograph or upload deed'),
        findsOneWidget,
      );
      expect(find.text('Next — Review & Publish'), findsOneWidget);
    });
  });

  group('ClientPostProjectPage - Review & Publish', () {
    testWidgets('renders review step for repairs (Step 3 of 3) and publishes', (
      tester,
    ) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.repairs))
        ..add(const ClientPostProjectScopeChanged('Repair kitchen sink'))
        ..add(const ClientPostProjectMinBudgetChanged(500))
        ..add(const ClientPostProjectMaxBudgetChanged(1500))
        ..add(const ClientPostProjectLocationChanged('الرياض · حي النرجس'))
        ..add(const ClientPostProjectStepAdvanced()) // step 2
        ..add(const ClientPostProjectStepAdvanced()); // step 3 (review)

      await pumpLocalizedApp(tester, buildPage(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('الخطوة 3 من 3'), findsOneWidget);
      expect(find.text('مراجعة تفاصيل المشروع'), findsOneWidget);
      expect(
        find.text(
          'راجع بيانات المشروع قبل النشر. بعد النشر ستصلك عروض الأسعار من المقاولين المعتمدين.',
        ),
        findsOneWidget,
      );
      expect(find.text('إصلاحات داخل المنزل'), findsOneWidget);
      expect(find.text('Repair kitchen sink'), findsOneWidget);
      expect(find.text('500 — 1500 ر.س'), findsOneWidget);
      expect(find.text('الرياض · حي النرجس'), findsOneWidget);
      expect(find.text('لا يلزم صك'), findsOneWidget);
      expect(find.text('نشر المشروع'), findsOneWidget);

      final publishButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(publishButton.onPressed, isNotNull);

      // Tap publish
      await tester.tap(find.text('نشر المشروع'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('تم نشر المشروع بنجاح'), findsOneWidget);
    });

    testWidgets('renders review step for deed project (Step 4 of 4)', (
      tester,
    ) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse))
        ..add(const ClientPostProjectScopeChanged('Build modern villa'))
        ..add(const ClientPostProjectMinBudgetChanged(300000))
        ..add(const ClientPostProjectMaxBudgetChanged(600000))
        ..add(const ClientPostProjectLocationChanged('الرياض · حي المروج'))
        ..add(
          const ClientPostProjectDeedSelected(
            filePath: 'deed.pdf',
            fileName: 'deed.pdf',
          ),
        )
        ..add(const ClientPostProjectStepAdvanced()) // step 2
        ..add(const ClientPostProjectStepAdvanced()) // step 3
        ..add(const ClientPostProjectStepAdvanced()); // step 4 (review)

      await pumpLocalizedApp(tester, buildPage(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('الخطوة 4 من 4'), findsOneWidget);
      expect(find.text('تأسيس منزل'), findsOneWidget);
      expect(find.text('300000 — 600000 ر.س'), findsOneWidget);
      expect(find.text('قيد مراجعة الصك'), findsOneWidget);
      expect(find.text('نشر المشروع'), findsOneWidget);
    });

    testWidgets('renders English strings for review step', (tester) async {
      final bloc = ClientPostProjectBloc()
        ..add(const ClientPostProjectTypeSelected(ClientProjectType.repairs))
        ..add(const ClientPostProjectScopeChanged('Plumbing'))
        ..add(const ClientPostProjectMinBudgetChanged(200))
        ..add(const ClientPostProjectMaxBudgetChanged(400))
        ..add(const ClientPostProjectLocationChanged('Riyadh'))
        ..add(const ClientPostProjectStepAdvanced())
        ..add(const ClientPostProjectStepAdvanced());

      await pumpLocalizedApp(
        tester,
        buildPage(bloc: bloc),
        locale: AppLocalization.english,
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Review Project Details'), findsOneWidget);
      expect(find.text('Publish Project'), findsOneWidget);
    });
  });
}
