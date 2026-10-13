import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/localization/app_localization.dart';
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

      // Tap dropdown to open menu
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
}
